# Methods that don't return QuerySets

## Aggregate

This method will return a hash with the aggregation result.

Valid aggregations are: MAX, MIN, SUM and AVG.

```ruby
caesar = User.objects.get(first_name: 'Julius', last_name: 'Caesar')

# Average number of stars of the posts written by Julius Caesar
caesar.objects.aggregate(avg_stars: Babik.agg(:avg, 'posts::stars')) # {avg_stars: 3.45}

# Other way to do it
caesar.objects(:posts).aggregate(avg_stars: Babik.agg(:avg, 'stars')) # {avg_stars: 3.45}
```

```ruby
# Average number of stars of users with last name 'Fabia'
User.objects.filter(last_name: 'Favbia').aggregate(avg_stars: Babik.agg(:avg, 'posts::stars')) # {avg_stars: 4.5}

# Min number of stars of users with last name 'Fabia'
User.objects.filter(last_name: 'Favbia').aggregate(min_stars: Babik.agg(:min, 'posts::stars')) # {min_stars: 1}

# Max number of stars of users with last name 'Fabia'
User.objects.filter(last_name: 'Favbia').aggregate(min_stars: Babik.agg(:min, 'posts::stars')) # {max_stars: 5}

# Sum of number of stars of users with last name 'Fabia'
User.objects.filter(last_name: 'Favbia').aggregate(sum_of_stars: Babik.agg(:sum, 'posts::stars')) # {sum_of_stars: 5}
```

## All

This method will run the QuerySet and return a query result for your query
(e.g. [PG Result](https://www.rubydoc.info/gems/pg/PG/Result)). 

You don't have to call this method directly unless you want to explicitly
use the query result instead of the QuerySet.

## Brackets

If the brackets operator takes an integer, it will return the ActiveRecord of this QuerySet in that position.

```ruby
# Will return 15 users from the 5th one
User.objects.filter('first_name': 'Romulus').order_by(first_name: :ASC)[5]

# SELECT users.*
# FROM users
# WHERE first_name = 'Romulus'
# ORDER BY first_name ASC
# LIMIT 1 OFFSET 5
```

If there is no ActiveRecord in that position, nil will be returned.

[There is also other way to use to return a section of the QuerySet](/doc/api/queryset/return_queryset.md#brackets).

No negative index is allowed.

## Count

Just call **count** method on the QuerySet to return the number of objects
that match your selection.

Call count method to return the number of ActiveRecord objects that match the filter.

### Aliases

- length
- size

### Examples

```ruby
# Number of users with the name Marcus
User.filter(first_name: 'Marcus').count

# Number of users created yesterday
yesterday_limits = [Time.zone.now.beginning_of_day, Time.zone.now.end_of_day]
User.filter(created_at__between: yesterday_limits).count

# Number of users with the surname Smith with an email
User.filter(last_name: 'Smith', email__isnull: false).count

# Number of users created yesterday
User.filter(last_name: 'Smith').count

# Number of users whose geozone is described as a desert.
# That is, contains the desert word (case insensitive).
User.filter(last_name: 'Smith', 'zone::description__icontains': 'desert').count

# Number of users with the surname Smith that have a post tagged with 'history'
User.filter(last_name: 'Smith', 'posts::tags::name': 'history').count
```

## Delete

Delete a bunch of objects by selecting a local or foreign condition.

### Local conditions

```ruby
# Deletes the tags with name 'book'
Tag.objects.filter(name: 'book').delete

# Deletes the users with a gmail email
User.objects.filter(email__endswith: '@gmail.com').delete
```

### Foreign conditions

```ruby
# Deletes the posts tagged as 'war'
Post.objects.filter('tags::name': 'war').delete
```

```ruby
# Deletes the tags of all posts of user called 'Aulus'
Tag.objects.filter('posts::author::first_name': 'Aulus').delete

# Other way to do it by calling delete operation by using an user instance
aulus_user = User.objects.get(first_name: 'Aulus')
aulus_user.objects('posts::tags').filter(name: 'war').delete
```


## Earliest

Return the first element according to the specified sort.
It is the reverse method of [latest](#latest).

**earliest** method accepts the same order parameters than [order_by](/doc/api/queryset/methods/return_queryset.md#order-by).

```ruby
User.objects.filter(last_name: 'García').earliest('first_name')
# SELECT users.* FROM users
# WHERE last_name = 'García'
# ORDER BY first_name ASC
# LIMIT 1
```

Also accepting descendant order, of course:

```ruby
User.objects.filter(last_name: 'Luna').earliest('-first_name')
# SELECT users.* FROM users
# WHERE last_name = 'Luna'
# ORDER BY first_name DESC
# LIMIT 1
```

And it is possible to order the QuerySet by a foreign condition:

```ruby

User.objects
    .filter([{first_name: 'Iacobus'}])
    .order_by('zone::name', 'last_name')
# SELECT users.*
# FROM users
# INNER JOIN geo_zones ON users.geo_zone_id = geo_zones_id 
# WHERE first_name = 'Iacobus'
# ORDER BY geozones.name ASC, last_name ASC
# LIMIT 1 
```


## Exists

Check if there is any record that matches the QuerySet conditions.

```ruby
puts 'There is at least one user called Aulus' if User.objects.get(first_name: 'Aulus').exists?
```

Also, there is a method **exist?** alias of this **exists?**.

## Fetch

Returns the element with the index parameter.

If there is no element at that position, if it has a default value, will return it.

If there is no default value, will raise an IndexError exception.

```ruby
# There are only 10 users 'Smith'

# Returns an user (index is in bounds because is less than 10) 
fifth_smith = User.filter(last_name: 'Smith').fetch(5)

# Returns the default value
# (index is not in bounds and a default value is present)
default_value_for_smith = User.filter(last_name: 'Smith').fetch(10_000, 'No user')

# Will raise an IndexError exception
# (index is not in bounds and there is no default value) 
bad_luck_smith = User.filter(last_name: 'Smith').fetch(10_000)
```

No negative index is allowed.

## First

Returns the first element of the QuerySet. If the QuerySet is empty, it will return nil.

```ruby
# Return the user with the first name Marcus, whose last name
# is the first one (descending order). 
User.filter(first_name: 'Marcus').order_by([:last_name, :DESC]).first

# Return nil because the first name 'Marcux' is not present in the database
User.filter(first_name: 'Marcux').order_by([:last_name, :DESC]).first
```

## Get

Return the ActiveRecord that matches the condition.

If there is no matching object, will raise a RuntimeError exception 'Does not exist'.
If there is more than one matching object, will raise a RuntimeError exception 'Multiple objects returned'.

```ruby
# Given this initial data
User.create!(first_name: 'Rollo', last_name: 'Lothbrok')
User.create!(first_name: 'Ragnar', last_name: 'Lothbrok')
User.create!(first_name: 'Sigurd', last_name: 'Ring')

# Will raise a 'Does not exist' exception
User.objects.get(last_name: 'Hamundarson') 

# Will raise a 'Multiple objects returned' exception
User.objects.get(last_name: 'Lothbrok')

# Will return a User ActiveRecord
User.objects.get(last_name: 'Ring')
```

## Latest

Return the last element according to the specified sort.
It is the reverse method of [earliest](#earliest).

**latest** method accepts the same order parameters than [order_by](/doc/api/queryset/methods/return_queryset.md#order-by).

```ruby
User.objects.filter(last_name: 'García').latest('first_name')
# SELECT users.* FROM users
# WHERE last_name = 'García'
# ORDER BY first_name DESC
# LIMIT 1
```

Also accepting descendant order, of course:

```ruby
User.objects.filter(last_name: 'Luna').latest('-first_name')
# SELECT users.* FROM users
# WHERE last_name = 'Luna'
# ORDER BY first_name ASC
# LIMIT 1
```

## None

Return an empty database-specific query result.

Use when you want to emptying of a QuerySet.

See [all](#all).

## Project

Many times there is no need to get the full object. In that case we
can make use of the projections.

### Basic usage

By calling the method **project** of the QuerySet, an
[ActiveRecord Result](http://api.rubyonrails.org/classes/ActiveRecord/Result.html)
will be returned with the projected fields.

**No values are type-casted**. All fields will be returned as-is (e.g.: datetimes as strings). 

They can be local and also foreign fields.

Examples:

```ruby
# Return a projection of the first name, email and country of
# all the users with the last name 'García'
p User.objects
    .filter('last_name': 'García')
    .order_by('first_name')
    .project('first_name', 'email', %w[zone::name country])
# [{first_name: 'Alarico', email: 'alarico@example.com', country: 'Spain'}]
```

Note in the example how the zone name is returned as the field country.
An alias of a column is defined by passing an Array of two items
the first one will be the column and the second one the new name
that we want to use when returning the projection for this column
(the column alias).


### Transformations

Some times we want to transform a projected field, tunning the parameters
allows us to apply a lambda to each returned value of the column.

Just change the column name parameter to an array and add a Proc
as an item of this Array. e.g.:

```ruby
# Return a projection of the first name, last name in uppercase and email
# for all the users with email in the domain example.com
upcase = ->(s) { s.upcase } 
p User.objects
    .filter('email__endswith': '@example.com')
    .order_by('first_name')
    .project('first_name', ['last_name', upcase], ['email', 'main_email'])
# [{first_name: 'Alarico', main_email: 'alarico@example.com', last_name: 'GARCÍA'}]
```

Note it is possible to combine alias and transformation
(note the order of the items in the parameter Array is not important), e.g.

```ruby
# Return a projection of the first name, last name and email
# for all the users with email in the domain example.com
# both first name and last name will have their diacritics removed
require 'i18n'
remove_diacritics = ->(string) { I18n.transliterate(string) }
clean_surname = ->(s) { remove_diacritics.call(s).upcase }
p User.objects
    .filter('email__endswith': '@example.com')
    .order_by('first_name')
    .project(
      ['first_name', 'name', remove_diacritics],
      ['last_name', clean_surname, 'surname'],
      'email'
    )
# [{name: 'Alarico', email: 'alarico@example.com', surname: 'GARCIA'}]
```


## Select related

When looping through a set of objects, it is usual to have to load the same
foreign objects in each loop. Traditionally, the simplest way to do it is to
make a query in each loop.

Hovewer, the best way to do it, is by loading the required foreign objects
and the begining and reading in the corresponding loop iteration.

Babik differs from Django in the interface but the idea remains the same:

```ruby
# Load the first 5 users with their corresponding zone
User.objects.limit(size: 5).select_related([:zone]).each do |user_with_zone|
  user, foreign_objects = user_with_zone
  puts "#{foreign_objects[:zone]} is the zone of user #{user.first_name}}"
end
```

This feature **only works in association paths that follow belongs_to
or has_one association**. Many to many associations are not implemented
because they requires a special treatment.

```ruby
# Load the posts with 4 or more stars with their author and category
Post.objects
    .filter(stars__gte: 4)
    .select_related([:author, :category]).each do |post_and_co|
  post, foreign_objects = post_and_co
  author = foreign_objects[:author]
  category = foreign_objects[:category]
  puts "#{author.first_name} wrote #{post.title} in the category #{category.name}"
end
```

## Set operations

Set operations have the same interface than the QuerySet, so
they can be **counted**, **limited**, **sorted** and of course
accessed as if they were QuerySets.

### Operations

#### Union

Makes a union between two QuerySets.

**Implemented for database adapters mysql2, postgresql, sqlite3**.

Given two QuerySets, over the same model, join the results (without repeated records)
and return it.

```ruby
q1 = User.objects.filter(first_name: 'Antinous')
q2 = User.objects.filter(first_name: 'Julius')
union = q1.union(q2)
# 
# Get all users named 'Antinous' or 'Julius'
# 
# SELECT *
# FROM users
# WHERE first_name = 'Antinous' 
# UNION
# SELECT *
# FROM users
# WHERE first_name = 'Julius' 
```

#### Intersection

Makes a intersection between two QuerySets.

**Implemented for database adapters postgresql and sqlite3**.

Compute the records that match the conditions defined in each
one of the operand queries of the intersection.

```ruby
q1 = User.objects.filter(first_name: 'Julius')
q2 = User.objects.filter(last_name: 'Fabia')
intersection = q1.intersection(q2)
# 
# Get all users named 'Julius' of the family 'Fabia'
# 
# SELECT *
# FROM users
# WHERE first_name = 'Julius' 
# INTERSECT
# SELECT *
# FROM users
# WHERE first_name = 'Fabia' 
```

#### Difference

Makes a difference between two QuerySets.

**Implemented for database adapters postgresql and sqlite3**.

Compute the records that match the conditions defined in the first
query but not the ones that are present in the second.

```ruby
q1 = User.objects.filter(first_name: 'Julius')
q2 = User.objects.filter(last_name: 'Fabia')
difference = q1.difference(q2)
# 
# Get all users named 'Julius' of other families than 'Fabia'
# 
# SELECT *
# FROM users
# WHERE first_name = 'Julius' 
# EXCEPT
# SELECT *
# FROM users
# WHERE first_name = 'Fabia' 
```

### Set Operation Chaining

It is also possible to chain several set operations:

```ruby
User.objects.filter(last_name: 'Aebutia')
    .union(User.objects.filter(last_name: 'Fabia'))
    .union(User.objects.filter(last_name: 'Atilia'))
    .union(User.objects.filter(last_name: 'Claudia'))
    .union(User.objects.filter(last_name: 'Cloelia'))
# Computes the union of all QuerySets
```

## Update

Updates the objects according to the queryset filter/exclude condition.

```ruby
# Set 5 stars to all posts whose title starts with 'Hello'
Post.filter(title__startswith: 'Hello')
    .update(stars: 5)
```

```ruby
# Increment by one the stars of the 222 user's posts that starts with 'Hello'
user = User.objects.get(id=222)
user.objects(:posts)
    .filter(title__startswith: 'Hello')
    .update(stars: Babik::QuerySet::Update::Assignment::Increment.new('stars'))
```

```ruby
# Set the title_length attribute of all posts
# Note the SQL inserted as a string in Function object.
Post.objects
    .update(stars: Babik::QuerySet::Update::Assignment::Function.new('title_length', 'LENGTH(title)'))
```