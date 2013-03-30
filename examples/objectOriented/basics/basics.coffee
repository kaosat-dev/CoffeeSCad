#coffeeSCad is based on coffeescript, which is an object oriented language, this means you can use things such as

class MyObject
  constructor:(size)->
    @size = size

#Inheritance (notice the use of "extends")
class OtherObject extends MyObject
  constructor:(size)->
    super(size) #you need to pass the parameters to the parent class
