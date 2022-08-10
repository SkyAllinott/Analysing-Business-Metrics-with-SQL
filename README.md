# Analysing Business Metrics with SQL
## Overview
I utilise mySQL's "classicmodels" database to answer various questions that may be asked of that company's data/business analyst. **All queries and questions can be found in the Analysis.sql file**.

## What questions do I answer?
Using this database, I can answer several questions. Some examples include: 
1. The fastest paying customers 
2. The sales rep with the most sales
3. Which reps sell more than X sales rep
4. Most ordered product line by country (with subtotals)
5. What's sitting on our shelves and who should we sell it to

And many others which can be found in the Analysis.sql file. 

## What techniques do I use?
A few of the techniques I use in these queries are:
1. Multi table (>2) joins
   - Let's you merge multiple tables together to get more results
     - Let's you connect tables that are not directly connected to one another
2. Subqueries
   - Subqueries let you compare results of two queries
     - For instance, this let's you return the list of all sales reps with more sales than employee X, in one efficient query
3. Stored procedures
   - These are essentially just functions with parameters
     - For instance, this let's you easily return the list of all employees in X office, without having to alter the query itself each time
4. Window functions
   - These are functions that work across table ROWS, and not columns
     - For instance, we can create a column that gives the time between each order for a given company
5. Rollups
   - Rollups give you subtotals
     - If we have countries and product lines A & B, rollups let you see each countries orders for A & B, the aggregate for that country, and the aggregate for all companies in all countries

And many others, which you can see in the Analysis.sql file. 

## Database Overview:

I include the schema diagram below.

![schema](https://user-images.githubusercontent.com/52394699/183797476-0d0b4866-93c4-4e94-a36f-2ea16f1ba1ad.png)

