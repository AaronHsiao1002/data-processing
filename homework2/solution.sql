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
CREATE TABLE query1 AS
SELECT genres.name, genreid_counts.count
FROM genres
INNER JOIN genreid_counts
ON genres.genreid = genreid_counts.genreid;

--SELECT * FROM query1;



/************************ QUERY 2 *************************/
/*
Write a SQL query to return the average rating per genre. Your query result should be saved
in a table called “query2” which has two attributes: “name” attribute is a list of all genres,
and “rating” attribute is a list of average rating per genre.
*/

-- get average rating and movieid attributes
DROP TABLE IF EXISTS rating_avgs CASCADE;
SELECT movieid, avg(rating)
INTO TEMP rating_avgs
FROM ratings
GROUP BY movieid;

-- join with hasagenre to get genreid and movies with avg ratings
DROP TABLE IF EXISTS rating_w_genreid CASCADE;
SELECT hasagenre.genreid, rating_avgs.avg
INTO TEMP rating_w_genreid
FROM hasagenre
    INNER JOIN rating_avgs
    ON rating_avgs.movieid = hasagenre.movieid;

-- get average of all movies with the same genre
DROP TABLE IF EXISTS genre_avgs CASCADE;
SELECT genreid, avg(avg)
INTO TEMP genre_avgs
FROM rating_w_genreid
GROUP BY genreid;

-- join genreid average rating to get genre name
DROP TABLE IF EXISTS query2 CASCADE;
CREATE TABLE query2 AS
SELECT genres.name, genre_avgs.avg
FROM genres
    INNER JOIN genre_avgs
    ON genres.genreid = genre_avgs.genreid;

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
INTO comedy_movieids
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
SELECT avg(query5.average)
FROM query5
    INNER JOIN query4
    ON query4.title = query5.title;

-- SELECT * FROM query6;


/************************ QUERY 7 *************************/
/*
Write a SQL query to return the average rating for all movies and each of these movies
is both “Comedy” and “Romance”. Your query result should be saved in a table called
“query7” which has one attribute: “average”.
*/

-- get movieids of comedy and romance movies
DROP TABLE IF EXISTS comedy_romance_movieids CASCADE;
SELECT hasagenre.movieid, hasagenre.genreid
INTO comedy_romance_movieids
FROM hasagenre
WHERE hasagenre.genreid IN
    (
        SELECT genres.genreid
        FROM genres
        WHERE name IN ('Comedy', 'Romance')
    );

-- get average rating from all movies in comedy_romance_movieids table
DROP TABLE IF EXISTS query7 CASCADE;
CREATE TABLE query7 (average) AS
SELECT avg(rating_avgs.avg)
FROM rating_avgs
    INNER JOIN comedy_romance_movieids
    ON rating_avgs.movieid = comedy_romance_movieids.movieid;

-- SELECT * FROM query7;



/************************ QUERY 8 *************************/

/*
Write a SQL query to return the average rating for all movies and each of these movies
is “Romance” but not “Comedy”. Your query result should be saved in a table called
“query8” which has one attribute: “average”.
*/

-- does this mean return the average rating for Romance movies?
-- get romance movieids
DROP TABLE IF EXISTS romance_movieids CASCADE;
SELECT hasagenre.movieid, hasagenre.genreid
INTO romance_movieids
FROM hasagenre
WHERE hasagenre.genreid IN
(
    SELECT genres.genreid
    FROM genres
    WHERE name = 'Romance'
);

-- join romance movie ids with their average ratings, averge the overall rating
DROP TABLE IF EXISTS query8 CASCADE;
CREATE TABLE query8 (average) AS
SELECT avg(rating_avgs.avg)
FROM rating_avgs
    INNER JOIN romance_movieids
    ON rating_avgs.movieid = romance_movieids.movieid;

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
WHERE ratings.userid = :v1;

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

-- get movieids that user :v1 hasn't rated, store in "unrated"
DROP TABLE IF EXISTS unrated CASCADE;
SELECT DISTINCT ratings.movieid
INTO TEMP unrated
FROM ratings
WHERE ratings.userid != :v1
ORDER BY ratings.movieid;


-- join unrated movies with avg rating table
DROP TABLE IF EXISTS unrated_w_avg CASCADE;
CREATE TABLE unrated_w_avg(movieid_unrated, average_unrated) AS
SELECT unrated.movieid, rating_avgs.avg
FROM unrated
    INNER JOIN rating_avgs
    ON rating_avgs.movieid = unrated.movieid;


-- join user rated movies with avg rating table
DROP TABLE IF EXISTS rated_w_avg CASCADE;
CREATE TABLE rated_w_avg(movieid_rated, average_rated) AS
SELECT query9.movieid, rating_avgs.avg
FROM query9
    INNER JOIN rating_avgs
    ON rating_avgs.movieid = query9.movieid;


-- perform cartesian product join (cross join) between the two sets
DROP TABLE IF EXISTS combinations CASCADE;
CREATE TABLE combinations
(
    movieid_unrated INT,
    avg_rating_unrated NUMERIC,
    movieid_rated INT,
    avg_rating_rated NUMERIC,
    similarity NUMERIC GENERATED ALWAYS AS (1 - (abs(avg_rating_unrated - avg_rating_rated) / 5)) STORED
);

INSERT INTO combinations
SELECT unrated_w_avg.movieid_unrated,
        unrated_w_avg.average_unrated,
        rated_w_avg.movieid_rated,
        rated_w_avg.average_rated
FROM unrated_w_avg
    CROSS JOIN rated_w_avg
ORDER BY rated_w_avg.movieid_rated;

-- SELECT * FROM combinations;

-- create sum of all unrated movies' (I) similarity scores with all user rated movies (L)

-- join combinations with user ratings
DROP TABLE IF EXISTS user_ratings CASCADE;
CREATE TABLE user_ratings
(
    movieid_unrated INT,
    avg_rating_unrated NUMERIC,
    movieid_rated INT,
    avg_rating_rated NUMERIC,
    similarity NUMERIC,
    user_rating NUMERIC
);
INSERT INTO user_ratings
SELECT combinations.movieid_unrated,
        combinations.avg_rating_unrated,
        combinations.movieid_rated,
        combinations.avg_rating_rated,
        combinations.similarity,
        query9.rating
FROM combinations
    INNER JOIN query9
    ON query9.movieid = combinations.movieid_rated;

-- SELECT * FROM user_ratings;



DROP TABLE IF EXISTS sim_sums CASCADE;
CREATE TABLE sim_sums (
    movieid_unrated INT,
    numerator NUMERIC,
    sim_sum NUMERIC,
    recommendation_score NUMERIC GENERATED ALWAYS AS (numerator / sim_sum) STORED
);

INSERT INTO sim_sums
SELECT user_ratings.movieid_unrated, sum(user_ratings.similarity * user_ratings.user_rating), sum(user_ratings.similarity)
FROM user_ratings
GROUP BY user_ratings.movieid_unrated;

-- SELECT * FROM sim_sums;

-- join movieids with movie titles where rating where rating > 3.9
DROP TABLE IF EXISTS recommended_movieids CASCADE;
SELECT sim_sums.movieid_unrated, sim_sums.recommendation_score
INTO TEMP recommended_movieids
FROM sim_sums
WHERE sim_sums.recommendation_score > 3.9;

-- SELECT * FROM recommended_movieids;

DROP TABLE IF EXISTS recommendation CASCADE;
CREATE TABLE recommendation (title) AS
SELECT movies.title
FROM movies
    INNER JOIN recommended_movieids
    ON movies.movieid = recommended_movieids.movieid_unrated;

SELECT * FROM recommendation;

