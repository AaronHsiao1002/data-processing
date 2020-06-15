#!/usr/bin/python2.7
#
# Assignment2 Interface
#

import psycopg2
import os
import sys

DATABASE_NAME = 'dds_assignment'
RANGE_TABLE_PREFIX = 'RangeRatingsPart'
RROBIN_TABLE_PREFIX = 'RoundRobinRatingsPart'
RANGE_METADATA_TABLE = 'RangeRatingsMetadata'
RROBIN_METADATA_TABLE = 'RoundRobinRatingsMetadata'

# Donot close the connection inside this file i.e. do not perform openconnection.close()
# metadata table format from Assignment1 file: RangeRatingsMetadata (PartitionNum, MinRating, MaxRating)
# RoundRobinRatingsMetadata(PartitionNum INT, TableNextInsert INT)
def RangeQuery(ratingsTableName, ratingMinValue, ratingMaxValue, openconnection):

    cur = openconnection.cursor()

    """ GET RANGE PARTITION TUPLES """
    # get partition numbers that include rows in the rating range of the passed parameters
    cur.execute(
        "SELECT PartitionNum FROM %s WHERE MinRating BETWEEN %s AND %s OR MaxRating BETWEEN %s AND %s"
        % (RANGE_METADATA_TABLE, ratingMinValue, ratingMaxValue, ratingMinValue, ratingMaxValue)
    )
    partitions = cur.fetchall()

    rows = []
    # get tuples/rows from selected partitions
    for part in partitions:
        part_name = RANGE_TABLE_PREFIX + str(part[0])
        cur.execute(
            "SELECT * FROM %s WHERE Rating BETWEEN %s AND %s "
            % (part_name, ratingMinValue, ratingMaxValue)
        )

        tuples = cur.fetchall()
        for row in tuples:
            rows.append([part_name] + list(row))


    """ GET ROUND ROBIN PARTITION TUPLES """
    cur.execute(
        "SELECT table_name FROM information_schema.tables WHERE table_name LIKE 'roundrobinratingspart%'"
    )

    part_names = cur.fetchall()
    print(part_names)
    for part_name in part_names:
        part_name = part_name[0]
        print("Querying: ", part_name)
        cur.execute(
            "SELECT * FROM %s WHERE Rating BETWEEN %s AND %s "
            % (part_name, ratingMinValue, ratingMaxValue)
        )
        tuples = cur.fetchall()
        for row in tuples:
            rows.append([part_name] + list(row))

    # write tuples/rows
    writeToFile("RangeQueryOut.txt", rows)



def PointQuery(ratingsTableName, ratingValue, openconnection):
    pass


def writeToFile(filename, rows):
    f = open(filename, 'w')
    for line in rows:
        f.write(','.join(str(s) for s in line))
        f.write('\n')
    f.close()
