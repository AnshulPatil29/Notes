# MySQL

## 1. Getting Started with MySQL

### 1.1 How SQL can help you

#### What it helps in:

- Reduced record filling time

- Reduced record retrieval time

- Flexible retrieval order

- Flexible output format

- Simultaneous multiple-user access to records

- Remote access to and electronic transmission of records

### 1.2 A Sample Database (Skipped)

### 1.3 Basic Database Terminology

#### 1.3.1 Structural Terminology

The **database** is a repository for the information you store, structure in a simple, regular fashion.

- The collection of data in a database is organized into **tables**.

- Each row in a table is a **record**.

- Records can contain several pieces of information; each **column** in a table corresponds to one of those pieces. 

The **management system** is the software that lets you use your data by enabling you to insert, retrieve, modify or delete records.

The **relational** in RDBMS indicated a type of DBMS which is particularly good at relating information stored in one table to information stored in other by joining related information to answer questions that cant be solved with information from one table alone.

#### 1.3.2 Query Language Terminology

Communication with DBMS takes place with **SQL**(Structured Query Language).

#### 1.3.3 MySQL Architectural Terminology

When using MySQL, we are using at least two programs, because MySQL operated on *client/server* architecture. One program is the MySQL server, `mysqld`. 

The server runs on the machine where your databased are stored. It listens for client requests coming on over the network and access database contents according to those requests to provide clients with the information they ask for.

The other programs are client programs; they connect to the database server and issue queries to tell it what information they want.

The most common client program is `mysql`, an interactive program that lets you issue queries and see the result.

Two administrative clients are `mysqldump`, a backup program that dumps table contents into a file, and `mysqladmin`, which enables you to check on the status of the server and perform other administrative tasks such as telling the server to shut down.

MySQL provides a client-programming library which lets you write your own programs if the standard clients are not suited for your requirement.

**Benefits of the client/server architecture**: (TLDR: separates control/management and accessing)

- The server enforces **concurrency control** to prevent two users from modifying the same record at the same time. All client requests go through the server, so the server sorts out who gets to do what, and when. 

- You need not be logged into the machine where your database is located. Since the database works in a networked environment, you can run the client program wherever you want, and access the database as long as you have access provided and access to the network.

### 1.4 A MySQL Tutorial

> Note: If the server is not running, run the service by running 
> 
> ```bash
> net start MySQL80
> ```

> This must be run in admin mode as services require admin privileges to run.

#### 1.4.5 Creating a Database

Using a database involves several steps:

- Creating the database

- Creating the tables within the database

- Manipulating the tables by inserting, retrieving, modifying, or deleting data

To create a new database user `CREATE DATABASE <database-name>`

```sql
CREATE DATABASE sampdb;
```

You might expect that creating a database would make it the default database, but you need to select it to use it. You can see this by running:

```sql
SELECT DATABASE();
```

Hence to select the database run:

```sql
USE sampdb;
```

Another way to use a database is to name it on the command line when you invoke mysql:

```bash
mysql sampdb
```

That is, in fact, the **usual way** to select the database you want to use. If you need any connection parameters, specify them on the command line. For example the following command enables the `sampadm` user to connect to the `sampdb` database on the local host:

```bash
mysql -p -u sampadm sampdb
```

#### 1.4.6 Creating Tables

The `president` table:

- **Name**: Names can be represented in a table several ways, such as a single column containing the entire name, or separate columns for the first and last name. It's simpler to use a single column but that limits your flexibility. To avoid these limitations, our `president` table  will use separate columns for the first and last name.
  
  This has a complication. Some names have 'Jr.' at the end, where will this go? This does not work as either First name or Last name, hence to fix this we need a suffix column. This shows that even a single record can cause problems.

- **Birthplace**: We will store this using *city* and *state* as with the name for the flexibility.

- **Birth date and death date**: The special problem here is we cannot require the death date column to be filled as some presidents are still living. Hence these will be filled with `NULL` , a special value indicating lack of any value.

The `member` table:

I am simply mentioning the fields as the above example shows the reasoning process aptly:

- **Name**: First name, Last name and suffix

- **ID number**: Unique identifier

- **Expiration Date**

- **Email Address**

- **Postal address**: Needed for contacting members without email. Columns:- street address, city, state, and ZIP code.

- **Phone number**

- **Special Interest Keywords**



##### Creating the historical league tables:

To create a table, the statement has the general form of 

```sql
CREATE TABLE tbl_name (column_specs)
```

For the `president` table, write the `CREATE TABLE` statement as follows:

```sql
CREATE TABLE president 
(
	last_name VARCHAR(15) NOT NULL,
    first_name VARCHAR(15) NOT NULL,
	suffix VARCHAR(5) NULL,
    city VARCHAR(20) NOT NULL,
    state CHAR(2) NOT NULL,
    birth DATE NOT NULL,
    death DATE NULL
);
```

This can be executed in shell or saved to a file and run using 

```bash
mysql sampdb < create_president.sql
```

- Here `VARCHAR(max_size)` indicates that that column allows for variable length strings with maximum length of `max_size`.

- `NOT NULL` indicates that this value must exist and cannot be NULL. Since suffix may or may not exists(similarly death date), these must be NULLABLE.

- `suffix` is set to `CHAR(2)` as all states are represented by ***exactly 2***  characters.

- **IMPORTANT**: The `DATE` datatype follows the SQL standard date representation of `CCYY-MM-DD` (also knows as "ISO 8601 format") where `CC`, `YY` , `MM` and `DD` represent the century, year, month and day respectively.

For the `member` table, the `CREATE TABLE` statement looks like this:

```sql
CREATE TABLE member
(
	member_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    PRIMARY KEY(member_id),
    last_name VARCHAR(20) NOT NULL,
    first_name VARCHAR(20) NOT NULL,
    suffix VARCHAR(5) NULL,
    expiration DATE NULL,
    email VARCHAR(100) NULL,
    street VARCHAR(100) NULL,
    city VARCHAR(100) NULL,
    state CHAR(2) NULL,
    zip VARCHAR(10) NULL,
    phone VARCHAR(20) NULL,
    interests VARCHAR(255) NULL
);
```

Lets breakdown the `member_id` definition:

- `INT` signifies integer datatype

- `UNSIGNED` prohibits negative values

- `NOT NULL` makes this a required data field to create a row

- `AUTO_INCREMENT` is a special attribute in MySQL. It indicates that the column holds sequence numbers, The `AUTO_INCREMENT` mechanism works like this: If you provide no value for the `member_id` column when you create a new `member` table row, MySQL automatically generates the next sequence number and assigns it to the column. This special behavior also occurs if you assign it the value `NULL`.

- `PRIMARY KEY` indicates that this column is indexed to enable fast lookups. It also sets up the `NOT NULL` and `UNIQUE` constraint.

- Note: MySQL requires `AUTO_INCREMENT` to have some kind of index (no idea what it means but seemed important to note here so I can refer back later)  
