---
title: "Go API Part 1"
date: 2021-04-01T06:39:47+03:00
summary: "intro to REST APIs with Go"
draft: false
tags: ["tutorial", "programming", "golang", "api"]
---

## Intro
This is going to be a simple tutorial about creating a backend web service that can be accessed over a REST API.
The application is going to be able to do something very basic just to make everyone familiar with the basics.
There will eventually be a part 2 where we will make an application that performs the basic CRUD(Create Read Update Delete) actions, it will include real-life applicable data and actions as well as a database for storing information.
Let's start then.

## Getting set up
I'm not going to cover how to set up the development environment but you can look at these links:
- https://golangdocs.com/install-go-linux
- https://golangdocs.com/install-go-windows
- https://golangdocs.com/install-go-mac-os

## Greeting the world
First off, in a file called `main.go` we declare the package (important note here, if the package is not `main` then there is no ability to use `go run` on it), add a couple basic imports, write the main function and make it print something:

{{< highlight go >}}
package main

import (
	"fmt"
)

func main() {
	fmt.Println("ordering facilities online")
}
{{< / highlight >}}

And that's our hello world right there.
Use `go run main.go` to run the program.

## Webbing it up
Alright now that that's done, let's start messing with the web capabilities.
First we'll select a port depending on if the `PORT` environment variable has been set or not and then we'll write a simple endpoint that returns the current year.
While we're at it I'll switch out `fmt` for `log` because I like the output better:

{{< highlight go >}}
package main

import (
	"log"
	"net/http"
	"os"
	"strconv"
	"time"
)

func getCurrentYear(w http.ResponseWriter, r *http.Request) {
	currentTime := time.Now()
	year := currentTime.Year()
	yearString := strconv.Itoa(year)
	w.Header().Set("Content-Type", "text/plain")
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("current year is: "+yearString))
	return
}

func main() {
	log.Println("ordering facilities online")
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	http.HandleFunc("/year", getCurrentYear)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
{{< / highlight >}}

A couple things to comment on.
First off, `:=` means that you don't have to manually declare the type of the variable, it will be figured out automatically by the compiler.
Second, the signature of the `getCurrentYear` function.
The arguments might look weird: `w http.ResponseWriter, r *http.Request` but those two variables are passed to the function by `http.HandleFunc`.
ResponseWriter `w` allows us to work with what we'll return and Request `r` gives us info about the request.
Let's get into the `getCurrentYear` function.
The first thing it does is get the year which is of type `int` and then using string converter (strconv) to make it a string in order to be able to be added together with our message in the end.
After creating `yearString` we se the content type so the client (in this case the browser) knows what we're sending and set the status to OK (code 200) so the client knows how things went.
The responsewriter writes a slice (indicated by `[]`) of bytes to the client which in this case is the message `current year is: ` along with the year as calculated previously.
Inside the main function we have `http.HandleFunc("/year", getCurrentYear)` which says that if you visit `/year` then the function `getCurrentYear` should be run.
This function is also called a handler because it handles the request.
Lastly, we run `http.ListenAndServe(":"+port, nil)` inside `log.Fatal` because it returns an error if it exists so if any error with starting the http server happens, we'll see it and the program won't run.
To test all of this, run `go run main.go` and then open a browser, visit `localhost:8080/year` and see the magic.

## JSONify our Year
To give a simple introduction to data structures and the JSON format we'll work with.
First we'll make a struct which will be our custom type for representing the year with some annotations.
We'll also import `encoding/json` to translate the struct to json based on the annotations and return it to the client.
In addition, we'll adjust some code accordingly.

{{< highlight go >}}
package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"time"
)

type MyYear struct {
	CurrentYear int    `json:"currentyear"`
	Good        bool   `json:"good,omitempty"`
	Comment     string `json:"comment,omitempty"`
}

func getCurrentYear(w http.ResponseWriter, r *http.Request) {
	currentTime := time.Now()
	year := currentTime.Year()
	var goodYear bool
	var comment string
	if (year == 2020 || year == 2021) {
		goodYear = false
		comment = "big oof"
	}
	myCurrentYear := MyYear{
		CurrentYear: year,
		Good: goodYear,
		Comment: comment,
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(myCurrentYear)
	return
}

func main() {
	log.Println("ordering facilities online")
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	http.HandleFunc("/year", getCurrentYear)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
{{< / highlight >}}

Alright so there is a lot to go over.
First off, the struct `MyYear` is our custom type. 
It has 3 fields, `CurrentYear` to store the year as an integer, `Good` to store a boolean about the year being good or not and `Comment` for the year.
The things next to each field in the struct specify the name that the json field will have as well as if it should be printed when the field is empty (specified by `omitempty`).
The content type was changed to `application/json` since that is what we're returning.
In the code above, `myCurrentYear` is created when the request is sent according to some conditions.
There is a little if statement that sets a default value for `Good` and `Comment` if the year is 2020 or 2021.
The variables `goodYear` and `comment` are declared without a default value and if we hadn't used them the compiler would error out but we did so that's not an issue just something to keep in mind.
All of the translation of the struct to json is done automatically, we just created a new json encoder that encodes into the responsewriter aka to the client and then encoded our struct.
If you run `go run main.go` now and then visit `localhost:8080/year` you will see that now the response is in json, exactly what we wanted.

## Adding a dependency
Eventually we will want to be able to do a GET request on something like `example.com/api/v1/orders/521` and get back the details of the 521st order in JSON format.
This requires some routing as well as reading path parameters, in this case that parameter is `521`.
For this purpose we'll use a request multiplexer, specifically `gorilla/mux`.
To add it to our system we can just do `go get github.com/gorilla/mux` and then add it as a dependency as shown below:

{{< highlight go >}}
package main

import (
	"encoding/json"
	"github.com/gorilla/mux"
	"log"
	"net/http"
	"os"
	"time"
)

type MyYear struct {
	CurrentYear int    `json:"currentyear"`
	Good        bool   `json:"good,omitempty"`
	Comment     string `json:"comment,omitempty"`
}

func getCurrentYear(w http.ResponseWriter, r *http.Request) {
	currentTime := time.Now()
	year := currentTime.Year()
	var goodYear bool
	var comment string
	if (year == 2020 || year == 2021) {
		goodYear = false
		comment = "big oof"
	}
	myCurrentYear := MyYear{
		CurrentYear: year,
		Good: goodYear,
		Comment: comment,
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(myCurrentYear)
	return
}

func main() {
	log.Println("ordering facilities online")
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	router := mux.NewRouter()
	router.HandleFunc("/year", getCurrentYear)
	log.Fatal(http.ListenAndServe(":"+port, router))
}
{{< / highlight >}}

We've added it, notice how `http.ListenAndServe` has a second argument now instead of `nil`.
Also instead of `http.HandleFunc` we have `router.HandleFunc` since the handler is no longer the default one from `net/http`.
Now if you visit `localhost:8080/year` you'll notice that json is returned just like before.
I didn't comment on it previously but did you notice the lack of `good` in the json response?
Why is that? We explicitly set a value so what's the deal there?
In the case of a `bool` variable, `false` is considered to be the "empty" state of the variable so it's not shown.
All we need to do to fix it is remove the `omitempty` from its annotation (as well as the comma) and we'll get the result we want.
Here is the finished code then:

{{< highlight go >}}
package main

import (
	"encoding/json"
	"github.com/gorilla/mux"
	"log"
	"net/http"
	"os"
	"time"
)

type MyYear struct {
	CurrentYear int    `json:"currentyear"`
	Good        bool   `json:"good"`
	Comment     string `json:"comment,omitempty"`
}

func getCurrentYear(w http.ResponseWriter, r *http.Request) {
	currentTime := time.Now()
	year := currentTime.Year()
	var goodYear bool
	var comment string
	if (year == 2020 || year == 2021) {
		goodYear = false
		comment = "big oof"
	}
	myCurrentYear := MyYear{
		CurrentYear: year,
		Good: goodYear,
		Comment: comment,
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(myCurrentYear)
	return
}

func main() {
	log.Println("ordering facilities online")
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	router := mux.NewRouter()
	router.HandleFunc("/year", getCurrentYear)
	log.Fatal(http.ListenAndServe(":"+port, router))
}
{{< / highlight >}}

Adding `gorilla/mux` didn't do a lot, we have added no extra functionality to our program but added a dependency which is generally not good.
The next part will focus more on the awesome things we can do with `gorilla/mux` related to paths, subrouters, regular expressions and matching HTTP verbs.

## Conclusion
This was a pretty heavy introduction to Go with an emphasis on using it for web services.
Feel free to run the examples, tweak them, add to them and become familiar with documentation.
Next time we'll be getting into full CRUD operations, databases and probably a Dockerfile too.
Thank you for reading, I hope you enjoyed and maybe learned something.
