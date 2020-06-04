/************************ QUERY 1 *************************/
/*
Write a SQL query to return the total number of movies
for each genre. Your query result should be saved in a table called “query1” which has two attributes:
“name” attribute is a list of genres, and “moviecount” list of movie counts for each genre.
*/

-- count occurences of genreid
DROP TABLE IF EXISTS genreid_counts CASCADE;
SELECT genreid, count(movieid)
INTO TEMP genreid_counts
FROM hasagenre
GROUP BY genreid
ORDER BY genreid;

-- get genre names from genreid
DROP TABLE IF EXISTS query1 CASCADE;
CREATE TABLE query1 (name, moviecount) AS
SELECT genres.name, genreid_counts.count
FROM genres
INNER JOIN genreid_counts
ON genres.genreid = genreid_counts.genreid;

-- SELECT * FROM query1;



/************************ QUERY 2 *************************/
/*
Write a SQL query to return the average rating per genre. Your query result should be saved
in a table called “query2” which has two attributes: “name” attribute is a list of all genres,
and “rating” attribute is a list of average rating per genre.
*/

-- join genres with ratings
DROP TABLE IF EXISTS all_ratings CASCADE;
SELECT hasagenre.genreid, hasagenre.movieid, ratings.rating
INTO TEMP all_ratings
FROM hasagenre
INNER JOIN ratings ON ratings.movieid = hasagenre.movieid
ORDER BY hasagenre.genreid;

-- sum ratings by genreid
DROP TABLE IF EXISTS genre_rating_avg CASCADE;
SELECT all_ratings.genreid, avg(all_ratings.rating)
INTO TEMP genre_rating_avg
FROM all_ratings
GROUP BY all_ratings.genreid;

-- join to get genre name
DROP TABLE IF EXISTS query2 CASCADE;
CREATE TABLE query2 (name, rating) AS
SELECT genres.name, genre_rating_avg.avg
FROM genres
    INNER JOIN genre_rating_avg
    ON genres.genreid = genre_rating_avg.genreid;

-- SELECT * FROM query2;



/************************ QUERY 3 *************************/
/*
Write a SQL query to return the movies which have at least 10 ratings. Your query result should be saved
in a table called “query3” which has two attributes: “title” is a list of movie titles,
and “CountOfRatings” is a list of ratings.
*/

-- count number of ratings for each movieid, select on >= 10
DROP TABLE IF EXISTS ratings_counts CASCADE;
SELECT movieid, count(*)::BIGINT
INTO TEMP ratings_counts
FROM ratings
GROUP BY movieid
HAVING count(*) >= 10
ORDER BY movieid;

-- join table to get movie titles from movieids
DROP TABLE IF EXISTS query3 CASCADE;
CREATE TABLE query3 (title, countofratings) AS
SELECT movies.title, ratings_counts.count
FROM movies
    INNER JOIN ratings_counts
    ON movies.movieid = ratings_counts.movieid;

-- SELECT * FROM query3;



/************************ QUERY 4 *************************/
/*
Write a SQL query to return all “Comedy” movies, including movieid and title. Your query
result should be saved in a table called “query4” which has two attributes: “movieid” is a list of movie ids,
and “title” is a list of movie titles.
*/

-- get genreid for comedy movies and get all movieids with comedy genre id
DROP TABLE IF EXISTS comedy_movieids CASCADE;
SELECT hasagenre.movieid, hasagenre.genreid
INTO TEMP comedy_movieids
FROM hasagenre
WHERE hasagenre.genreid =
(
    SELECT genres.genreid
    FROM genres
    WHERE name = 'Comedy'
);

-- get all movie titles with comedy movieids
DROP TABLE IF EXISTS query4 CASCADE;
CREATE TABLE query4 (movieid, title) AS
SELECT movies.movieid, movies.title
FROM movies
    INNER JOIN comedy_movieids
    ON comedy_movieids.movieid = movies.movieid;


-- SELECT * FROM query4;



/************************ QUERY 5 *************************/
/*
Write a SQL query to return the average rating per movie. Your query result should be
saved in a table called “query5” which has two attributes: “title” is a list of movie titles,
and “average” is a list of the average rating per movie.
*/

-- get average rating and movieid attributes

DROP TABLE IF EXISTS rating_avgs CASCADE;
SELECT movieid,
       avg(rating) INTO TEMP rating_avgs
FROM ratings
GROUP BY movieid;

-- get movie title from movieid
DROP TABLE IF EXISTS query5 CASCADE;
CREATE TABLE query5 (title, average) AS
SELECT movies.title, rating_avgs.avg
FROM movies
    INNER JOIN rating_avgs
    ON rating_avgs.movieid = movies.movieid;

 -- SELECT * FROM query5 WHERE title = 'Where the Heart Is (2000)';


/************************ QUERY 6 *************************/
/*
Write a SQL query to return the average rating for all “Comedy” movies. Your query result
should be saved in a table called “query6” which has one attribute: “average”.
*/

DROP TABLE IF EXISTS query6 CASCADE;
CREATE TABLE query6 (average) AS
SELECT query2.rating
FROM query2
WHERE query2.name = 'Comedy';

-- SELECT * FROM query6;


/************************ QUERY 7 *************************/
/*
Write a SQL query to return the average rating for all movies and each of these movies
is both “Comedy” and “Romance”. Your query result should be saved in a table called
“query7” which has one attribute: “average”.
*/

DROP TABLE IF EXISTS romance_movieids;
SELECT hasagenre.movieid,
       hasagenre.genreid INTO TEMP romance_movieids
FROM hasagenre
WHERE hasagenre.genreid =
        ( SELECT genres.genreid
         FROM genres
         WHERE name = 'Romance' );

DROP TABLE IF EXISTS romance_and_comedy_movieids;
SELECT movieid
INTO TEMP romance_and_comedy_movieids
FROM romance_movieids
INTERSECT
SELECT movieid
FROM comedy_movieids;

-- get average rating from all movies
DROP TABLE IF EXISTS query7 CASCADE;
CREATE TABLE query7 (average) AS
SELECT avg(rating)
FROM ratings
    INNER JOIN romance_and_comedy_movieids
    ON ratings.movieid = romance_and_comedy_movieids.movieid;

-- SELECT * FROM query7;



/************************ QUERY 8 *************************/

/*
Write a SQL query to return the average rating for all movies and each of these movies
is “Romance” but not “Comedy”. Your query result should be saved in a table called
“query8” which has one attribute: “average”.
*/

-- get romance and not comedy movieids
DROP TABLE IF EXISTS romance_not_comedy_movieids;
SELECT movieid INTO TEMP romance_not_comedy_movieids
FROM romance_movieids EXCEPT
SELECT movieid
FROM comedy_movieids;

-- join romance movie ids with their average ratings, averge the overall rating
DROP TABLE IF EXISTS query8 CASCADE;
CREATE TABLE query8 (average) AS
SELECT avg(rating)
FROM ratings
INNER JOIN romance_not_comedy_movieids ON ratings.movieid = romance_not_comedy_movieids.movieid;

-- SELECT * FROM query8;



/************************ QUERY 9 *************************/
/*
Find all movies that are rated by a user such that the userId is equal to v1.
The v1 will be an integer parameter passed to the SQL query. Your query result
should be saved in a table called “query9” which has two attributes: “movieid”
is a list of movieid’s rated by userId v1, and “rating” is a list of ratings
given by userId v1 for corresponding movieid.
*/

-- get ratings from user :v1 (passed on command line)
DROP TABLE IF EXISTS query9 CASCADE;
CREATE TABLE query9 (movieid, rating) AS
SELECT ratings.movieid, ratings.rating
FROM ratings
WHERE ratings.userid = :v1
ORDER BY ratings.movieid;

-- SELECT * FROM query9;



/************************ QUERY 10 *************************/
/*
Write an SQL query to create a recommendation table* for a given user. Given a userID v1,
you need to recommend the movies according to the movies he has rated before. In particular,
you need to predict the rating P of a movie “i” that the user “Ua” didn’t rate. In the
following recommendation model, P(Ua, i) is the predicted rating of movie i
for User Ua. L contains all movies that have been rated by Ua. Sim(i,l) is the similarity
between i and l. r is the rating that Ua gave to l.
*/


-- get sim score for all possible combinations of movies
DROP TABLE IF EXISTS rating_avgs_copy;
CREATE TABLE rating_avgs_copy AS
TABLE rating_avgs;

DROP TABLE IF EXISTS all_combos_sim;
CREATE TABLE all_combos_sim (movieid1, movieid2, sim) AS
SELECT rating_avgs.movieid, rating_avgs_copy.movieid, (1 - (abs(rating_avgs.avg - rating_avgs_copy.avg) / 5))
FROM rating_avgs
CROSS JOIN rating_avgs_copy;

-- SELECT * FROM all_combos_sim WHERE movieid1 = 3565 AND movieid2 = 2026;

-- get movieids that user :v1 hasn't rated, store in "unrated"

DROP TABLE IF EXISTS unrated CASCADE;
SELECT movies.movieid INTO TEMP unrated
FROM movies
WHERE NOT EXISTS
        (SELECT
         FROM query9
         WHERE query9.movieid = movies.movieid );


-- SELECT * FROM unrated;

-- filter movieid1 column based on what the user hasn't rated
DROP TABLE IF EXISTS unrated_combos_sim;
CREATE TABLE unrated_combos_sim (unrated_movieid, movieid2, sim) AS
SELECT unrated.movieid, all_combos_sim.movieid2, sim
FROM all_combos_sim
    INNER JOIN unrated
    ON unrated.movieid = all_combos_sim.movieid1;

-- filter movieid2 column based on what the user has rated, include their rating
DROP TABLE IF EXISTS unrated_rated_combos;
CREATE TABLE unrated_rated_combos (unrated_movieid, rated_movieid, sim, user_rating) AS
SELECT unrated_combos_sim.unrated_movieid, query9.movieid, unrated_combos_sim.sim, query9.rating
FROM unrated_combos_sim
    INNER JOIN query9
    ON query9.movieid = unrated_combos_sim.movieid2;

-- SELECT * FROM unrated_rated_combos;

-- calculate recommended score based on columns
DROP TABLE IF EXISTS rec_scores CASCADE;
CREATE TABLE rec_scores (
    movieid_unrated INT,
    numerator NUMERIC,
    sim_sum NUMERIC,
    rec_score NUMERIC GENERATED ALWAYS AS (numerator / sim_sum) STORED
);

INSERT INTO rec_scores
SELECT
    unrated_rated_combos.unrated_movieid,
    sum(unrated_rated_combos.sim * unrated_rated_combos.user_rating),
    sum(unrated_rated_combos.sim)
FROM unrated_rated_combos
GROUP BY unrated_rated_combos.unrated_movieid;

-- SELECT * FROM rec_scores;

-- join movieids with movie titles where rating where rating > 3.9
DROP TABLE IF EXISTS recommended_movieids CASCADE;
SELECT rec_scores.movieid_unrated, rec_scores.rec_score
INTO TEMP recommended_movieids
FROM rec_scores
WHERE rec_scores.rec_score > 3.9
ORDER BY rec_scores.movieid_unrated;

--SELECT * FROM recommended_movieids;

DROP TABLE IF EXISTS recommendation CASCADE;
CREATE TABLE recommendation (title) AS
SELECT movies.title
FROM movies
    INNER JOIN recommended_movieids
    ON movies.movieid = recommended_movieids.movieid_unrated;

-- SELECT count(*) FROM recommendation;

