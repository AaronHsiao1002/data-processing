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
