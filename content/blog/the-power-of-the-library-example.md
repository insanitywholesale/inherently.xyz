---
title: "The Power of the Library Example"
date: 2021-05-06T14:25:41+03:00
draft: false
tags: ["programming", "opinion"]
---

## Intro
While considering what kind of example I could use for a service that was supposed to be a tech demo, I settled on a catalog/library of books.
I think it's a powerful example because it includes the basic CRUD operations and also allows for a lot of flexibility and detail of implementation.
Below I'll try to explain the most important ones and maybe help convince you to rethink about it and maybe use it as the next step after the usual todo list one.

## The Library example
Let's start with an explanation of what this example actually is before going into its advantages.
It's pretty simple, you have a library of books and want to perform operations associated with managing a library.
Simple concept, simple to implement and uses real-life things that people have experience with and can reason about.
Is it really this simple though?
In the intro I said it's supposed to be a step-up from the usual todo list example but so far it doesn't seem different other than being another object in the place of a todo item.
Well, let's dive a little deeper.

## Data Structures
When you start, there is the dilemma of what fields/attributes to give the book.
The ISBN stands out as a convenient unique identifier which is great, then there is the title, the number of pages, year of release, format as in hard cover or soft cover or pdf or epub or mobi, edition, categor(y/ies), author, publisher, subtitle, cover art, bookmark for reading progress, description in the back cover, if you own it or not, did you lend it to someone or not, are you lending it from someone or not, if it's a physical copy where is it located and so on and so forth.
I think you get my point, you can get really deep into it if you want or pick some of the basics and go from there.
Are they really basics though?
Specifically when it comes to who wrote the book, it could be one person or it could be more than one.
Especially in technical books it's not unusual to have 2 or 3 authors so you're getting into a situation where you have something like the following (silly example but please stay with me):

```json
{
  "books": [
    {
      "ISBN": "0189219181",
      "Title": "hey",
      "Author": {
        "authors": [
          {
            "AuthorID": 1,
            "FirstName": "anguish",
            "MiddleName": "none",
            "LastName": "mental",
            "YearBorn": 404,
            "YearDied": 201,
            "BooksWritten": 5
          },
          {
            "AuthorID": 2,
            "FirstName": "big",
            "MiddleName": "boo",
            "LastName": "ba",
            "BooksWritten": 9543
          },
          {
            "AuthorID": 3,
            "FirstName": "me",
            "MiddleName": "notme",
            "LastName": "notyou",
            "YearBorn": 1999,
            "BooksWritten": 2
          }
        ]
      },
      "Year": 1999,
      "Edition": 1,
      "Publisher": {
        "PublisherID": 3,
        "Name": "urmom",
        "YearStarted": 1237,
        "YearEnded": 2077,
        "BooksPublished": 9001
      },
      "Pages": 100,
      "Category": "tech",
      "PDF": false,
      "Owned": true,
      "Lended": true
    }
  ]
}
```

Here we see that each author is inside an array which is the value of a key called `authors` which is the value of a key called `Author` which is a part of one of the objects in the array called `books` which is inside the outer JSON object.
Fairly complex, right?
Additionally, you have to pay attention to this throughout the entire application including saving it and retrieving it from a database, when passing it to other services that might use this data for example a cover art finder or a media aggregator service and when those services process it.
Following that, there are logistical considerations about storing an author or publisher twice since the client shouldn't have to deal with sending the right ID for the publisher or the author(s), checking if a book with the same ISBN exists, potentially handling cases where you bought it again cause the person you gave it to never gave it back and so on.
The main takeaway is that you can decide how real-world you want to make the example, add complexity at will and introduce edge cases that defy previously established preconditions such as the ISBN being a unique identifier.

## Functions
I touched on this before I believe it warrants repeating.
Similar to the data structure you go with, there several functions of differing depth you can implement.
The simple CRUD operations might be taken as a baseline but what even if that rule was able to be defied?
Do you want to delete the book or simply set a hidden state because you want the library to act as an archive?
Should the cases of the author's year of birth and death be allowed to be set incorrectly (like in the example above with author 1), partially (author 2) or not at all (author 3)?
Should the person that the library belongs to be able to mark the books as lended but not necessarily to who or should they be able to record who they lended the books to?
Are the books editable after being added or not?
Should there be a url for the digital edition visible to anyone or only a signed-in and authenticated person?
Do we even want to support multiple people using the same instance of this library service?
So many different things to consider and this can be a perfect opportunity to learn to use data while also being the one that defines what that data should look like.
You get be the one producing and consuming the data which is not the case with 3rd-party APIs thus giving you the opportunity to figure things out on the way there.
And speaking of accessing the data...

## Interfacing
I've only spoken about server-side stuff this far (unless you count the output of `jq -M` as a frontend) but let's round this out with the client-side.
I showed some example JSON previously but in the intro there was a mention of a tech demo and you can bet I'm [not writing REST]({{< ref "blog/rest-is-over" >}}) for this.
The main definition in my case is a [protobuf file](https://gitlab.com/insanitywholesale/bookdir/-/blob/master/proto/v1/bookdir.proto) so I get control of the struct only as far as the proto v3 syntax allows.
This presents an interesting challenge where there is limited or no option for annotations so no ORM ([gorm](https://gorm.io/) for golang) can be used.
Since I'm using gRPC with that and also want JSON to be able to be returned, a translation layer was used, [grpc-gateway](https://github.com/grpc-ecosystem/grpc-gateway) to be specific.
With the ability to use JSON to communicate, a cli, desktop, mobile or web client can be made in a variety of languages while not losing the great service-to-service communication that gRPC provides.
After having mostly nailed down the data structures I wanted to use and most of the entity-related functions I wanted to implement I decided to take a look at reactjs again.
A post about it will come later after I'm done with this project but the example is given to demonstrate that you can pick something that can make an http request and process JSON then run off with it and build something.
The way you choose access the library is noteworthy and can become another important part of using this concept as the example in a tutorial.

## Conclusion
I believe the book/library example to be a very good one as a second step after a todo list one due to the complexity that it allows to be introduced in the data structures, the functions, the interfaces and APIs as well as the possibilities it opens up.
Thank you for reading, I hope you enjoyed it and maybe learned something.
