# Methods that return QuerySets

## Brackets

If the brackets operator takes a range, the resultant QuerySet will be limited
in the form **[start..end]**.

```ruby
# Will return 15 users from the 5th one to the 20th one (both included).
User.objects.filter('first_name': 'Romulus').order_by(first_name: :ASC)[5..20]

# SELECT users.*
# FROM users
# WHERE first_name = 'Romulus'
# ORDER BY first_name ASC
# LIMIT 15 OFFSET 5
```

[There is also other way to use to return single ActiveRecord objects](/doc/api/queryset/dont_return_queryset.md#brackets).

### Distinct

Call **distinct** method when we are sure the result of your QuerySet
is going to return repeated columns but you want to ignore them.
For example, in case there is a many-to-many relationship.

```ruby
# If any user has more than one post tagged as 'history'
# it will be returned several times. Applying distinct
# will return only unique users.
User.objects
    .distinct
    .filter('posts::tags::name': 'history')
``` 

## Exclude

Filter out some objects that match some conditions.

Follows the same format than [Filter](#filter) but as an exclusion instead of
selection.

```ruby
# Select all users that are not named 'Paulus'
User.objects.exclude(first_name: 'Marcus')
```

```ruby
# Select all users that have not the last name 'Paulus' and that are not
# from 'Rome'.
# SELECT users.* FROM users
# INNER JOIN geo_zones ON users.geo_zone_id = geo_zones_id 
# WHERE NOT(last_name = 'Paulus' AND geo_zones.name = 'Rome')
User.objects.exclude(last_name: 'Paulus', 'zone::name': 'Rome')
```

## Filter

Filter is a method that allows to select the desired ActiveRecord objects.

It accepts two kind of parameters:

- A **hash**: then the selection conditions will all be fulfilled.
- An **array of hashes**: then at least one of the selection conditions of one of the item hashes must be fulfilled.

```ruby
# Return a QuerySet with all users whose first name is 'Iacobus' AND last name is 'Paulus'
User.objects.filter(first_name: 'Iacobus', last_name: 'Paulus')

# Return a QuerySet with all users whose first name is 'Iacobus' OR last name is 'Paulus'
User.objects.filter([{first_name: 'Iacobus'}, {last_name: 'Paulus'}])
```

Note the hash contains a simple structure where the key is always a name of a field
as a [symbol](https://ruby-doc.org/core/Symbol.html) and the value will be one
of the accepted values for each filed. Usually, a Ruby String, Number, Date or DateTime.

Thus, note that if a hash is passed as filter argument, its braces
are optional, leaving a more clean code:

```ruby
# Instead of
User.objects.filter({first_name: 'Iacobus', last_name: 'Paulus'})

# We can write
User.objects.filter(first_name: 'Iacobus', last_name: 'Paulus') 
```

### Combining exclude and filter

You can combine filter and exclude to create complex queries.

```ruby
# SELECT users.* FROM users
# INNER JOIN geo_zones ON users.geo_zone_id = geo_zones_id 
# WHERE last_name <> 'Paulus' AND NOT(geo_zones.name IN ('Rome', 'Utica'))
User.objects.filter([{first_name: 'Iacobus'}]).exclude('zone::name__in': ['Rome', 'Utica'])
```

```ruby
# SELECT users.* FROM users
# WHERE last_name <> 'Paulus' AND NOT(users.email LIKE '%example.com')
User.objects.filter({first_name: 'Iacobus'}).exclude({'email__endswith': 'example.com'})
```

## Local filters

A local filter is one that is composed by fields that belong to the
sender model. i. e. the model class caller.

```ruby
# Return the users created today whose name is 'Tiberius' or 'Pontius'
today = DateTime.today
User.objects
    .filter(created_at__date: today)
    .filter([{first_name: 'Tiberius'}, {first_name: 'Pontius'}])
```

## Foreign filters

A foreign filter is a filter that makes use of the [associations](http://guides.rubyonrails.org/association_basics.html)
defined on the ActiveRecord model.

Following RuboCop guidelines, [no has_and_belongs_to_many association
will work](https://www.rubydoc.info/gems/rubocop/RuboCop/Cop/Rails/HasAndBelongsToMany),
but only **belongs_to**, **has_one** and **has_many**.

Examples:

```ruby
# Return the users created today whose zone is 'Rome' or 'Utica'
today = DateTime.today
User.objects
    .filter(created_at__date: today)
    .filter([{'zone::name': 'Tiberius'}, {'zone::name': 'Utica'}])

# Also, if there is a belongs_to relationship, there is the option of
# passing directly the parent object 
tiberius = GeoZone.objects.get('Tiberius')
utica = GeoZone.objects.get('Utica')
User.objects
    .filter(created_at__date: today)
    .filter([{'zone': tiberius}, {zone: utica}])
```

```ruby
# Return the users that have posts with the following tags: 'history', 'heraldry', 'battle'
# Note a distinct is included to avoid having repeated users
today = DateTime.today
User.objects
    .distinct
    .filter(created_at__date: today)
    .filter([
      {'posts::tags::name': 'history'},
      {'posts::tags::name': 'heraldry'},
      {'posts::tags::name': 'battle'},
    ])
```

### Association scopes

At the moment, the implicit conditions defined in the
[association scopes](http://guides.rubyonrails.org/active_record_querying.html#scopes) **are ignored**.

More info about association scopes [here](https://ducktypelabs.com/using-scope-with-associations/).

## Field lookups

[Field lookups](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#field-lookups) are special operators that can be used to select objects by other conditions
than equality.

For example, comparisons like greater than, less or equal than or between two dates
can be made with lookups. i. e.

```ruby
# Return a QuerySet with all users created today
User.objects.filter(created_at__date: Date.today)
```

See [lookups documentation](/doc/api/queryset/lookups.md) for more information. 

## Limit

To limit the amount of results, use the **limit** method.

This method allows two parameters, size and offset.

Note this method will only works with DBMS that support LIMIT statement
(mainly MySQL, PostgreSQL and MariaDB). 

```ruby
# Will return the next 5 users starting from the first one.
User.objects.filter('zone::name': 'Rome').limit(size: 5)

# Will return the next 5 users starting from the sixth one.
User.objects.filter('zone::name': 'Rome').limit(size: 5, offset: 6)
```

## Select related

When looping through a set of objects, it is usual to have to load the same
foreign objects in each loop. Traditionaly, the simplest way to do it is to
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