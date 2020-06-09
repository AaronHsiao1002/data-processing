#!/usr/bin/python2.7
#
# Interface for the assignement
#

import psycopg2

def getOpenConnection(user='postgres', password='1234', dbname='postgres'):
    return psycopg2.connect("dbname='" + dbname + "' user='" + user + "' host='localhost' password='" + password + "'")


def loadRatings(ratingstablename, ratingsfilepath, openconnection):

    # create table
    cur = openconnection.cursor()
    cur.execute(
    """
    CREATE TABLE Ratings (
    UserID integer,
    tmp1 char,
    MovieID integer,
    tmp2 char,
    Rating float,
    tmp3 char,
    timestamp bigint,
    PRIMARY KEY (UserID, MovieID)
    )
    """
    )

    # load data
    with open('test_data.txt', 'r') as data:
        cur.copy_from(data, 'Ratings', sep=':')

    cur.execute(
    """
    ALTER TABLE Ratings
    DROP COLUMN tmp1,
    DROP COLUMN tmp2,
    DROP COLUMN tmp3,
    DROP COLUMN timestamp
    """
    )
    openconnection.commit()


def rangePartition(ratingstablename, numberofpartitions, openconnection):

    with openconnection.cursor() as cur:

        partition_size = 5 / numberofpartitions
        # partition by row and insert into separate fragment
        start_rating = 0
        for table_num in range(numberofpartitions):

            # query partition data
            end_rating = start_rating + partition_size
            if table_num == 0:
                cur.execute(
                    "SELECT * FROM {} WHERE {}.Rating >= {} AND {}.Rating <= {} ORDER BY Rating ASC"
                    .format(ratingstablename, ratingstablename, start_rating, ratingstablename, end_rating)
                )
            else:
                cur.execute(
                    "SELECT * FROM {} WHERE {}.Rating > {} AND {}.Rating <= {} ORDER BY Rating ASC"
                    .format(ratingstablename, ratingstablename, start_rating, ratingstablename, end_rating)
                )
            start_rating = end_rating

            # save queried data into temp table
            temp_table = cur.fetchall()

            # create table for fragment
            cur.execute("DROP TABLE IF EXISTS range_part{}".format(table_num))
            cur.execute(
                """
                CREATE TABLE range_part{} (
                    UserID int,
                    MovieID int,
                    Rating float,
                    PRIMARY KEY (UserID, MovieID)
                )
                """.format(table_num)
            )

            # load temp table into created table fragment
            for row in temp_table:
                cur.execute("INSERT INTO range_part{}(UserID, MovieID, Rating) VALUES ({},{},{})"
                .format(table_num, row[0], row[1], row[2]))


def roundRobinPartition(ratingstablename, numberofpartitions, openconnection):
    pass


def roundrobininsert(ratingstablename, userid, itemid, rating, openconnection):
    pass


def rangeinsert(ratingstablename, userid, itemid, rating, openconnection):
    pass

def createDB(dbname='dds_assignment'):
    """
    We create a DB by connecting to the default user and database of Postgres
    The function first checks if an existing database exists for a given name, else creates it.
    :return:None
    """
    # Connect to the default database
    con = getOpenConnection(dbname='postgres')
    con.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_AUTOCOMMIT)
    cur = con.cursor()

    # Check if an existing database with the same name exists
    cur.execute('SELECT COUNT(*) FROM pg_catalog.pg_database WHERE datname=\'%s\'' % (dbname,))
    count = cur.fetchone()[0]
    if count == 0:
        cur.execute('CREATE DATABASE %s' % (dbname,))  # Create the database
    else:
        print 'A database named {0} already exists'.format(dbname)

    # Clean up
    cur.close()
    con.close()

def deletepartitionsandexit(openconnection):
    cur = openconnection.cursor()
    cur.execute("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'")
    l = []
    for row in cur:
        l.append(row[0])
    for tablename in l:
        cur.execute("drop table if exists {0} CASCADE".format(tablename))

    cur.close()

def deleteTables(ratingstablename, openconnection):
    try:
        cursor = openconnection.cursor()
        if ratingstablename.upper() == 'ALL':
            cursor.execute("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'")
            tables = cursor.fetchall()
            for table_name in tables:
                cursor.execute('DROP TABLE %s CASCADE' % (table_name[0]))
        else:
            cursor.execute('DROP TABLE %s CASCADE' % (ratingstablename))
        openconnection.commit()
    except psycopg2.DatabaseError, e:
        if openconnection:
            openconnection.rollback()
        print 'Error %s' % e
    except IOError, e:
        if openconnection:
            openconnection.rollback()
        print 'Error %s' % e
    finally:
        if cursor:
            cursor.close()
