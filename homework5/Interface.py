#!/usr/bin/python2.7
#
# Assignment3 Interface
#

import psycopg2
import os
import sys

# Donot close the connection inside this file i.e. do not perform openconnection.close()
def ParallelSort (InputTable, SortingColumnName, OutputTable, openconnection):

    cur = openconnection.cursor()

    # create new table
    cur.execute(
        "CREATE TABLE %s(UserID INT, MovieID INT, Rating REAL)" % (OutputTable)
    )

    # get table data
    cur.execute(
        "SELECT * FROM %s ORDER BY %s" % (InputTable, SortingColumnName)
    )
    rows = cur.fetchall()

    # rewrite table
    for row in rows:
        cur.execute(
            "INSERT INTO %s(UserID, MovieID, Rating) VALUES (%s, %s, %s)" % (OutputTable, row[0], row[1], row[2])
        )



def ParallelJoin (InputTable1, InputTable2, Table1JoinColumn, Table2JoinColumn, OutputTable, openconnection):
    cur = openconnection.cursor()

    # create new table
    cur.execute(
        """
        CREATE TABLE %s AS
        SELECT *
        FROM %s
            INNER JOIN %s
            ON %s.%s = %s.%s
        """
        % (OutputTable, InputTable1, InputTable2, InputTable1, Table1JoinColumn, InputTable2, Table2JoinColumn)
    )

################### DO NOT CHANGE ANYTHING BELOW THIS #############################


# Donot change this function
def getOpenConnection(user='postgres', password='1234', dbname='postgres'):
    return psycopg2.connect("dbname='" + dbname + "' user='" + user + "' host='localhost' password='" + password + "'")

# Donot change this function
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
    con.commit()
    con.close()
