# NAME

csvdb - Database Operations for CSV Files

# VERSION

Version 0.0.2

# LICENCE AND COPYRIGHT

Copyright (c) 2017 Matthias Nott (mnott (at) mnsoft.org).

Licensed under WTFPL.

# INTRODUCTION

            The program was written to provide for database
            operations on csv files. You can run use it to
            analyze csv files as if they were database tables.

# SYNOPSIS

./csvdb.pl \[options\]

csvdb interprets all .csv files in the data directory as tables.
So if, for example, you do this:

    ./csvdb.pl -s "select distinct id, name from employee order by name"

Then this expects to find a file employee.csv in the data directory,
with at least a header line containing something like id, name, which
are going to be the column headers.

      Notice that column headers are going to be simplified in the sense
      that all special characters, including spaces, are replaced by
      underscores. If in doubt, use the "-c" option to get a list of
      column headers for your query.

Command line parameters can take any order on the command line.

    Options:

      General Options:

      -help            brief help message (alternatives: ?, -h)
      -man             full documentation (alternatives: -m)
      -d               debug (alternatives: -debug): Print out sql statements.

      csvdb Options:

      -dir data        The location of the csv files. Default: ./data/

      -c somefile      Show the csv columns in somefile.csv in alphabetical order
      -k somefile      Show the csv columns in somefile.csv in their original order

      -s "select..."   Execute a select statement

      -v somefile.sql  Execute a select statement in some file

      -p               Interpret the following as key=value pair for a query

      -r               Output the result of the query in csv format
      -h               When using -r, do not output the column headers
      -q               When using -q, quote all columns (also numbers)

      Other Options:

      -documentation   Recreate the README.md (needs pod2markdown)

# OPTIONS

- **-help**

    Print a brief help message and exits.

- **-man**

    Prints the manual page and exits.

- **-documentation**

    Regenerate the README.md file

- **-dir**

    Specify the directory within which the data files (.csv files)
    are to be located. Default is a directory "data" under the current
    directory.

- **-d**

    Print the generated sql statement to stderr. This can be useful
    if you receive errors from the database engine, in order to
    understand what was actually tried to select.

- **-c**

    Show the columns in a given file, in alphabetical order.

    For example:

        ./csvdb.pl -c employee
        id
        name

    This assumes that there is a file employee.csv in the data
    directory.

- **-k**

    Show the columns in a given file, in their original order.

    For example:

        ./csvdb.pl -k employee
        name
        id

    This assumes that there is a file employee.csv in the data
    directory.

- **-s**

    Run a query from the command line. For example:

        ./csvdb.pl -s "select distinct id, name from employee order by name"
        2, Hinz
        1, Kunz

    This assumes that there is a file employee.csv in the data
    directory.

- **-v**

    Run a query from a file. For example:

        ./cvsdb.pl -v employees.sql

    This assumes there is an employees.sql (you can give a path to
    that file) which contains the actual query. This file is called
    a view.

    Lines starting with a # are ignored, and all other lines are
    concatenated into one single line. If you are unsure about
    the resulting query, use the -d command line option.

    For example:

        #
        # Select for EMPLOYEE
        #
        # Parameters:
        #
        # none
        #
        select
          e.id                      as EmpId,
          e.name                    as EmpName
        from employee e
        order by
          e.name

- **-p**

    Any query, be it on the command line (where it doesn't make too
    much sense) or from a view file, can contain parameters. These
    can be specified on the command line, and if they exist, they
    are going to be replaced into the query. Here is a more complex
    query which uses CUSTOMER that it replaces into the query, and
    also an optional \_WHERE\_ placeholder which, if not specified on
    the command line, will be removed. Also, the following example
    shows how to join multiple tables (in the given example, we want
    to see from some pipeline.csv file only the products which we find
    in a products.csv file):

        ./csvdb.pl -v customer.sql -p CUSTOMER="New York Times" -p _WHERE_="and p.acv_keur > 100"

    Here is a more complex view:

        #
        # Select for CUSTOMER
        #
        # Parameters:
        #
        # CUSTOMER
        # _WHERE_ (optional)
        #
        select
          p.country                 as Country,
          p.bp_org_name             as Customer,
          p.opportunity_owner_name  as Opp_Owner,
          p.opportunity_id          as Opp_Id,
          p.closing_date            as Close_Date,
          p.opp_phase               as Phase,
          p.fc_qualification        as Category,
          p.opportunity_description as Opp_Desc,
          p.product                 as Product,
          p.product_desc            as Product_Desc,
          p.acv_keur                as ACV,
          p.tcv_keur                as TCV
        from pipeline p
        join hcp on p.product = hcp.product
        where
              p.revenue_type   = 'New Software'
          and p.opp_status     = 'In process'
          and p.bp_org_name    like '%CUSTOMER%'
          _WHERE_
        order by
          bp_org_name,
          tcv_keur desc

- **-r**

    Output the result of a query not in tabular, but in csv format.
    This is useful if you want to run further queries on the result
    of a given query. Notice that the column headers are going to be
    potentially different from the original table; special characters
    can be escaped using underscores, and also, you may have used the
    "AS" statement in the query.

- **-h**

    When using -r, do not output the column headers. This can be
    useful if you want to collect the results of multiple queries
    into one target file, appending as you go along.

- **-q**

    When using -r, quote all columns in the output - this may or
    may not be useful, as numbers are going to be quoted too with
    this option; when importing the resulting file into, for example,
    Excel, Excel will interpret them as text.