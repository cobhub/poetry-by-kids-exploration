--1. The poetry in this database is the work of children in grades 1 through 5.
select*
from grade;
select*
from author;
select*
from gender;
-- 1a. How many poets from each grade are represented in the data?
-- 1st: 623, 2nd: 1437, 3rd: 2344, 4th: 3288, 5th: 3464
select grade.name as grade, count(author.grade_id)
from author
join grade
on author.grade_id = grade.id
group by author.grade_id, grade.name
order by grade asc;

-- 1b. How many of the poets in each grade are Male?
--M1:243, M2:605, M3:948, M4:1241, M5:1294
select grade.name as grade, sum(gender.id) as male_count
from author
join grade
on author.grade_id = grade.id
join gender
on author.gender_id = gender.id
where gender.id = 1
group by grade.name, gender.id
order by grade asc;
--how many are Female?
--F1:326, F2:824, F3:1154, F4:1446, F5:1514
select grade.name as grade, sum(gender.id) as female_count
from author
join grade
on author.grade_id = grade.id
join gender
on author.gender_id = gender.id
where gender.id = 2
group by grade.name, gender.id
order by grade asc;
-- 1c. Briefly describe the trend you see across grade levels.
-- There is an increase in both male & female children as grade level progresses.
-- There are also more female children than male children across every grade level.


-- 2. Two foods that are favorites of children are pizza and hamburgers.
-- Which of these things do children write about more often? Pizza 106 titles
-- Which do they have the most to say about when they do? Pizza (avg word count of 209.03)
-- a. Return the total number of poems that mention pizza and total number that mention
-- the word hamburger in the TEXT or TITLE, also return the average character count for poems
-- that mention pizza and also for poems that mention the word hamburger in the TEXT or TITLE.
-- Do this in a single query, (i.e. your output should contain all the information).
select*
from poem;
--counts poem title/text including "pizza"
select count(title)
from poem
where title ilike '%piz%';
select count(text)
from poem
where text ilike '%piz%';
--counts poem title/text including "hamburger"
select count(title)
from poem
where title ilike '%hamb%';
select count(text)
from poem
where text ilike '%hamb%';
--finds average word count of text column for "pizza" ~> 49.96
select round(avg(char_count),2) as avg_pizza_word_count
from poem
where title ilike'%piz%';
--finds average word count of text column for "hamburger" ~> 48.29
select round(avg(char_count),2) as avg_hamburger_word_count
from poem
where title ilike '%hamb%';
--all-in-one
select
sum(case when title ilike '%piz%' then 1 else 0 end) as pizza_titles,
sum(case when title ilike '%hamb%' then 1 else 0 end) as hamburger_titles,
sum(case when text ilike '%piz%' then 1 else 0 end) as text_with_pizza,
sum(case when text ilike '%hamb%' then 1 else 0 end) as text_with_hamburger,
round(avg(case when title ilike '%piz%' then char_count else null end),2) as avg_pizza_word_count,
round(avg(case when title ilike '%hamb%' then char_count else null end),2) as avg_hamburger_word_count
from poem;


--3.Do longer poems have more emotional intensity compared to shorter poems? Length has no bearing on emotional intensity
--a. Start by writing a query to return each emotion in the database with
--its average intensity and average character count.
--Which emotion is associated with the longest poems on average? Anger at 261.16
--Which emotion has the shortest? Joy at 220.99

select e.name as emotion,
round(avg(intensity_percent),2) as avg_intensity,
round(avg(p.char_count),2) as avg_char_count
from poem_emotion as pe
join emotion as e
on pe.emotion_id = e.id
join poem as p
on pe.poem_id = p.id
group by e.name;

--b. Convert the query you wrote in part a into a CTE. Then find the 5 most
--intense poems that express anger and whether they are to be longer or shorter than
--the average angry poem.

--What is the most angry poem about? Summer
--Do you think these are all classified correctly? No. 5th angriest poem seems to be
--a sad poem but it includes words that are associated with anger, so it was incorrectly
--lumped in with the anger poems.
with cte as(
select e.name as emotion,
e.id as emotion_id,
round(avg(intensity_percent),2) as avg_intensity,
round(avg(p.char_count),2) as avg_char_count
from poem_emotion as pe
join emotion as e
on pe.emotion_id = e.id
join poem as p
on pe.poem_id = p.id
group by e.name, e.id
)
select e.name, pe.intensity_percent,
case when p.char_count < cte.avg_char_count then 'Shorter'
when p.char_count > cte.avg_char_count then 'Longer'
else 'Average' end anger_intensity_length,
p.text
from poem_emotion as pe
join poem as p 
on pe.poem_id = p.id
join emotion as e
on pe.emotion_id = e.id
join cte
using(emotion_id)
where pe.emotion_id = 1
group by p.text, e.name, pe.intensity_percent,p.char_count, cte.avg_char_count
order by pe.intensity_percent desc
limit 5;

-- 4. Compare the 5 most joyful poems by 1st graders to the 5 most joyful poems by 5th graders.

-- a. Which group writes the most joyful poems according to the intensity score? Fifth graders
-- b. How many times do males show up in the top 5 poems for each grade? Females?
--1st grade males: 2, 1st grade females: 1, 5th grade males: 3, 5th grade females: 1

select pe.intensity_percent, a.grade_id, a.gender_id,pe.emotion_id,
row_number() over (partition by a.grade_id order by pe.intensity_percent desc) as rank
from poem as p
join author as a
on p.author_id = a.id
join poem_emotion as pe
on p.id = pe.poem_id
where a.grade_id in(1,5)
and pe.emotion_id = 4;

with poems_ranked as (
select pe.intensity_percent, a.grade_id, a.gender_id,pe.emotion_id,
row_number() over (partition by a.grade_id order by pe.intensity_percent desc) as rank
from poem as p
join author as a
on p.author_id = a.id
join poem_emotion as pe
on p.id = pe.poem_id
where a.grade_id in(1,5)
and pe.emotion_id = 4
)
select intensity_percent, 
case when grade_id = 1 then 'First Grade'
when grade_id = 5 then 'Fifth Grade'
else null end as grade,
case when gender_id = 1 then 'Female'
when gender_id = 2 then 'Male'
when gender_id = 3 then 'Ambiguous'
when gender_id = 4 then 'NA'
else null end as gender,
case when emotion_id = 4 then 'Joy'
else null end as emotion
from poems_ranked
where rank <= 5
group by grade_id, gender_id, poems_ranked.rank, intensity_percent,emotion_id
order by grade_id, rank;

-- 5. Robert Frost was a famous American poet. There is 1 poet named robert per grade.

-- a. Examine the 5 poets in the database with the name robert.
--Create a report showing the distribution of emotions that characterize their work by grade.
-- b. Export this report to Excel and create an appropriate visualization that shows
--what you have found.
-- c. Write a short description that summarizes the visualization.

select 
case when a.id = 475 then 'Robert1'
when a.id = 1775 then 'Robert2'
when a.id = 3946 then 'Robert3'
when a.id = 6993 then 'Robert4'
when a.id = 10438 then 'Robert5'
else 'aintrobert' end name,
case when pe.emotion_id = 1 then 'Anger'
when pe.emotion_id = 2 then 'Fear'
when pe.emotion_id = 3 then 'Sadness'
when pe.emotion_id = 4 then 'Joy'
else 'Neutral' end as emotion,
case when a.grade_id = 1 then '1st'
when a.grade_id = 2 then '2nd'
when a.grade_id = 3 then '3rd'
when a.grade_id = 4 then '4th'
when a.grade_id = 5 then '5th'
else null end grade,
p.text
from poem as p
join author as a
on p.author_id = a.id
join poem_emotion as pe
on p.id = pe.poem_id
where a.name ilike 'robert'
group by a.name, a.id, p.text,pe.emotion_id;