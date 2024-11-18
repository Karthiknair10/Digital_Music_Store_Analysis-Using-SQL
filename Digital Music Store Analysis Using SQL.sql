''' Who is the senior most employee based on job title? '''
SELECT * FROM employee
ORDER BY levels DESC
LIMIT 1;

''' Which countries have the most Invoices? '''
SELECT COUNT(invoice_id) AS COUNTS, billing_country FROM invoice
GROUP BY billing_country
ORDER BY COUNTS DESC
LIMIT 1;

''' What are top 3 values of total invoice? '''
SELECT total FROM invoice
ORDER BY total DESC
LIMIT 3;

''' Which city has the best customers? We would like to throw a promotional Music
Festival in the city we made the most money. Write a query that returns one city that
has the highest sum of invoice totals. Return both the city name & sum of all invoice
totals '''
SELECT SUM(total) AS Invoice_total, billing_city FROM invoice
GROUP BY billing_city
ORDER BY Invoice_total DESC
LIMIT 1;

SELECT * FROM customer;
SELECT * FROM invoice;

''' Who is the best customer? The customer who has spent the most money will be
declared the best customer. Write a query that returns the person who has spent the
most money '''
SELECT c.customer_id, c.first_name, c.last_name, SUM(i.total) AS Total_invoice 
FROM customer AS c
INNER JOIN invoice AS i
ON c.customer_id = i.customer_id
GROUP BY c.customer_id
ORDER BY Total_invoice DESC
LIMIT 1;

''' Write query to return the email, first name, last name, & Genre of all Rock Music
listeners. Return your list ordered alphabetically by email starting with A '''
SELECT DISTINCT email, first_name, last_name
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
WHERE track_id IN(
	SELECT track_id FROM track
	JOIN genre ON track.genre_id = genre.genre_id
	WHERE genre.name = 'Rock'
)
ORDER BY email;

''' Lets invite the artists who have written the most rock music in our dataset. Write a
query that returns the Artist name and total track count of the top 10 rock bands '''
SELECT artist.artist_id, artist.name, COUNT(track.track_id) AS Total FROM track
JOIN album ON track.album_id = album.album_id
JOIN artist ON album.artist_id = artist.artist_id
JOIN genre ON track.genre_id = genre.genre_id
WHERE genre.name LIKE 'Rock'
GROUP BY artist.artist_id
ORDER BY Total DESC
LIMIT 10;

''' Return all the track names that have a song length longer than the average song length.
Return the Name and Milliseconds for each track. Order by the song length with the
longest songs listed first '''
SELECT name, milliseconds FROM track
WHERE milliseconds > (
SELECT AVG(milliseconds) AS Avg_length_track FROM track)
ORDER BY milliseconds DESC;


''' Find how much amount spent by each customer on artists? Write a query to return
customer name, artist name and total spent '''
WITH best_selling_artist AS (
SELECT artist.artist_id AS artist_id, artist.name AS artist_name, 
SUM(invoice_line.unit_price*invoice_line.quantity) AS Total_sales 
FROM invoice_line
JOIN track ON track.track_id = invoice_line.track_id
JOIN album ON album.album_id = track.album_id
JOIN artist ON artist.artist_id = album.artist_id
GROUP BY artist.artist_id
ORDER BY Total_sales DESC
LIMIT 1
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, 
SUM(il.unit_price*il.quantity) AS Amount_spent FROM invoice AS i
JOIN customer AS c ON c.customer_id = i.customer_id
JOIN invoice_line AS il ON il.invoice_id = i.invoice_id
JOIN track AS t ON t.track_id = il.track_id
JOIN album AS a ON a.album_id = t.album_id
JOIN best_selling_artist AS bsa ON bsa.artist_id = a.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC
;


''' We want to find out the most popular music Genre for each country. We determine the
most popular genre as the genre with the highest amount of purchases. Write a query
that returns each country along with the top Genre. For countries where the maximum
number of purchases is shared return all Genres '''
-- METHOD-1: --
WITH  popular_genre AS(
SELECT COUNT(invoice_line.quantity) AS purchases, customer.country, 
genre.name, genre.genre_id,
ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity)DESC) AS RowNo
FROM invoice_line 
JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
JOIN customer ON customer.customer_id = invoice.customer_id
JOIN track ON track.track_id = invoice_line.track_id
JOIN genre ON genre.genre_id = track.genre_id
GROUP BY 2,3,4
ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM popular_genre WHERE RowNo <= 1;

-- Method-2: --
WITH RECURSIVE
	sales_per_country AS(
	SELECT COUNT(invoice_line.quantity) AS purchases, customer.country, 
	genre.name, genre.genre_id
	FROM invoice_line 
	JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
	JOIN customer ON customer.customer_id = invoice.customer_id
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY 2,3,4
	ORDER BY 2 ASC
	),
	max_genre_per_country AS(
	SELECT MAX(purchases) AS max_genre_number, country
	FROM sales_per_country
	GROUP BY 2
	ORDER BY 2
	)
SELECT s.*, m.max_genre_number
FROM sales_per_country AS s JOIN max_genre_per_country AS m 
ON s.purchases = m.max_genre_number;


''' Write a query that determines the customer that has spent the most on music for each
country. Write a query that returns the country along with the top customer and how
much they spent. For countries where the top amount spent is shared, provide all
customers who spent this amount '''
-- Method-1: --
WITH RECURSIVE
	customer_with_country AS(
	SELECT customer.customer_id, customer.first_name, customer.last_name,
	invoice.billing_country, SUM(invoice.total) AS total_spending
	FROM invoice JOIN customer
	ON invoice.customer_id = customer.customer_id
	GROUP BY 1,2,3,4
	ORDER BY 1,5 DESC
	),
	countrywise_spending AS(
	SELECT billing_country, MAX(total_spending) AS max_spending
	FROM customer_with_country
	GROUP BY billing_country
	)
SELECT cc.customer_id, cc.first_name, cc.last_name, cc.billing_country, cc.total_spending
FROM customer_with_country AS cc
JOIN countrywise_spending as ct
ON cc.billing_country = ct.billing_country
WHERE cc.total_spending = ct.max_spending
ORDER BY 4;

-- Method-2: --
WITH RECURSIVE
	customer_with_country AS(
	SELECT customer.customer_id, customer.first_name, customer.last_name,
	invoice.billing_country, SUM(invoice.total) AS total_spending,
	ROW_NUMBER() OVER(PARTITION BY invoice.billing_country ORDER BY SUM(invoice.total) DESC) AS RowNo
	FROM invoice JOIN customer
	ON invoice.customer_id = customer.customer_id
	GROUP BY 1,2,3,4
	ORDER BY 4 ASC, 5 DESC
	)
SELECT * FROM customer_with_country WHERE RowNo <= 1; 

