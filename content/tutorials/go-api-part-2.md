---
title: "Go Api Part 2"
date: 2021-04-06T02:23:55+03:00
draft: true
summary: "REST API with golang part 2"
tags: ["tutorial", "programming", "golang", "api"]
---

## Previous relevant tutorial

## Intro
In this part we will be developing a full CRUD REST API in Go except without a real database because I realize that it's too much to go over at once.
The rest of what I promised is true though, we'll use real data that is more than just a basic todo, explore routing options, subrouters and even middleware.

## Starting point
The place we start at is a basic `main.go` file with our structs that represent the models we'll work with as well as a simple `gorilla/mux` setup.
The first part of CRUD that we will implement is the simplest one, Read.
More specifically reading all the entries.
We will also create a slice (essentially a list) of pointers for the instances of `Delivery` that will exist.
The HTTP Method we specify that we accept is `http.MethodGet` since whoever is accessing the API is getting data from us, not sending us anything.
In addition, we set the http status code to `http.StatusOK` in order to communicate that the request went well.

```go
package main

import (
	"encoding/json"
	"github.com/gorilla/mux"
	"log"
	"net/http"
)

type DeliveryDriver struct {
	FirstName string `json:"firstname"`
	LastName  string `json:"lastname"`
}

type Delivery struct {
	OrderNumber      int            `json:"ordernumber"`
	City             string         `json:"city"`
	Zipcode          string         `json:"zipcode"`
	Address          string         `json:"address"`
	Phone1           string         `json:"phone1"`
	Phone2           string         `json:"phone2,omitempty"`
	Cancelled        bool           `json:"cancelled"`
	Delivered        bool           `json:"delivered"`
	DeliveryAttempts int            `json:"deliveryattempts"`
	Driver           DeliveryDriver `json:"deliverydriver"`
}

// type deliveries is slice of Delivy pointers
type deliveryList []*Delivery

// variable deliveryList is of type deliveries
var deliveries deliveryList = []*Delivery{}

// Read all deliveries
func GetAllDeliveries(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(deliveries)
}

func main() {
	// Set up router
	router := mux.NewRouter()
	// Set up subrouter for api version 1
	apiV1 := router.PathPrefix("/api/v1").Subrouter()
	// Set up routes
	apiV1.HandleFunc("/deliveries", GetAllDeliveries).Methods(http.MethodGet)
	// Start http server
	log.Fatal(http.ListenAndServe(":8000", router))
}
```

As you can see it's fairly familiar.
The subrouter is based on the path so anything starting with `/api/v1` is sent to that subrouter and all the `HandleFunc` only needs to specify the path under the path of the subrouter, in this case `/deliveries`.
We can run this using `go run main.go` and visit `localhost:8000/api/v1/deliveries` to see a measly `[]` which is an empty json array.

## Get all
Let's add some data then, 3 example entries should suffice:

```go
package main

import (
	"encoding/json"
	"github.com/gorilla/mux"
	"log"
	"net/http"
)

type DeliveryDriver struct {
	FirstName string `json:"firstname"`
	LastName  string `json:"lastname"`
}

type Delivery struct {
	OrderNumber      int            `json:"ordernumber"`
	City             string         `json:"city"`
	Zipcode          string         `json:"zipcode"`
	Address          string         `json:"address"`
	Phone1           string         `json:"phone1"`
	Phone2           string         `json:"phone2,omitempty"`
	Cancelled        bool           `json:"cancelled"`
	Delivered        bool           `json:"delivered"`
	DeliveryAttempts int            `json:"deliveryattempts"`
	Driver           DeliveryDriver `json:"deliverydriver"`
}

// type deliveries is slice of Delivy pointers
type deliveryList []*Delivery

// variable deliveryList is of type deliveries
var deliveries deliveryList = []*Delivery{
	&Delivery{
		OrderNumber:      1,
		City:             "Here",
		Zipcode:          "52011",
		Address:          "Home",
		Phone1:           "6945123789",
		Phone2:           "2313722903",
		Cancelled: false,
		Delivered:        false,
		DeliveryAttempts: 0,
		Driver: DeliveryDriver{
			FirstName: "Mhtsos",
			LastName:  "Iwannou",
		},
	},
	&Delivery{
		OrderNumber:      2,
		City:             "There",
		Zipcode:          "1701",
		Address:          "Office",
		Phone1:           "6932728091",
		Cancelled: false,
		Delivered:        true,
		DeliveryAttempts: 1,
		Driver: DeliveryDriver{
			FirstName: "Lucas",
			LastName:  "Johnson",
		},
	},
	&Delivery{
		OrderNumber:      3,
		City:             "FarAway",
		Zipcode:          "920639",
		Address:          "Island",
		Phone1:           "6900777123",
		Cancelled: true,
		Delivered:        false,
		DeliveryAttempts: 24,
		Driver: DeliveryDriver{
			FirstName: "Pilotos",
			LastName:  "Aeroplanou",
		},
	},
}

// Read all deliveries
func GetAllDeliveries(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(deliveries)
}

func main() {
	// Set up router
	router := mux.NewRouter()
	// Set up subrouter for api version 1
	apiV1 := router.PathPrefix("/api/v1").Subrouter()
	// Set up routes
	apiV1.HandleFunc("/deliveries", GetAllDeliveries).Methods(http.MethodGet)
	// Start http server
	log.Fatal(http.ListenAndServe(":8000", router))
}
```

Now after running `go run main.go` and going to `localhost:8000/api/v1/deliveries` we can see a whole lot more and if you're using firefox you'll get some pretty sweet formatting too (that's due to setting `Content-Type` to `application/json`, if you delete that line it won't format it).

## Get one
Seeing all the entires is fine and dandy but we might want to see information about only one of them.
In contrast to the previous one where we used `/api/v1/deliveries` which means many (in fact it means all because we didn't specify a range), here we're going to do something different.
We'll use `/api/v1/delivery/ordernumber` (notice that `delivery` is singular) and we'll specify the ordernumber since it is unique as seen from the example entries.
As for the code within the function, we'll check the parameters to make sure that the argument is actually a number we can use to find the delivery and if it's fine we will return the delivery as JSON as well as set the status code to `http.StatusOK`.
However if it's wrong, we'll set the status code to `http.StatusNotFound` and then return an error message.

```go
package main

import (
	"encoding/json"
	"github.com/gorilla/mux"
	"log"
	"net/http"
	"strconv"
)

type DeliveryDriver struct {
	FirstName string `json:"firstname"`
	LastName  string `json:"lastname"`
}

type Delivery struct {
	OrderNumber      int            `json:"ordernumber"`
	City             string         `json:"city"`
	Zipcode          string         `json:"zipcode"`
	Address          string         `json:"address"`
	Phone1           string         `json:"phone1"`
	Phone2           string         `json:"phone2,omitempty"`
	Cancelled        bool           `json:"cancelled"`
	Delivered        bool           `json:"delivered"`
	DeliveryAttempts int            `json:"deliveryattempts"`
	Driver           DeliveryDriver `json:"deliverydriver"`
}

// type deliveries is slice of Delivy pointers
type deliveryList []*Delivery

// variable deliveryList is of type deliveries
var deliveries deliveryList = []*Delivery{
	&Delivery{
		OrderNumber:      1,
		City:             "Here",
		Zipcode:          "52011",
		Address:          "Home",
		Phone1:           "6945123789",
		Phone2:           "2313722903",
		Cancelled: false,
		Delivered:        false,
		DeliveryAttempts: 0,
		Driver: DeliveryDriver{
			FirstName: "Mhtsos",
			LastName:  "Iwannou",
		},
	},
	&Delivery{
		OrderNumber:      2,
		City:             "There",
		Zipcode:          "1701",
		Address:          "Office",
		Phone1:           "6932728091",
		Cancelled: false,
		Delivered:        true,
		DeliveryAttempts: 1,
		Driver: DeliveryDriver{
			FirstName: "Lucas",
			LastName:  "Johnson",
		},
	},
	&Delivery{
		OrderNumber:      3,
		City:             "FarAway",
		Zipcode:          "920639",
		Address:          "Island",
		Phone1:           "6900777123",
		Cancelled: true,
		Delivered:        false,
		DeliveryAttempts: 24,
		Driver: DeliveryDriver{
			FirstName: "Pilotos",
			LastName:  "Aeroplanou",
		},
	},
}

// Constant for Bad Request
const BadReq string = `{"error": "bad request"}`
// Constant for Not Found
const NotFound string = `{"error": "not found"}`

// Read all deliveries
func GetAllDeliveries(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(deliveries)
}

// Read a specific delivery
func GetDelivery(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	params := mux.Vars(r)
	orderNum, err := strconv.Atoi(params["ordernumber"])
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte(BadReq))
		return
	}
	for _, d := range deliveries {
		if d.OrderNumber == orderNum {
			w.WriteHeader(http.StatusOK)
			json.NewEncoder(w).Encode(d)
			return
		}
	}
	w.WriteHeader(http.StatusNotFound)
	w.Write([]byte(NotFound))
	return
}

func main() {
	// Set up router
	router := mux.NewRouter()
	// Set up subrouter for api version 1
	apiV1 := router.PathPrefix("/api/v1").Subrouter()
	// Set up routes
	apiV1.HandleFunc("/deliveries", GetAllDeliveries).Methods(http.MethodGet)
	apiV1.HandleFunc("/delivery/{ordernumber}", GetDelivery).Methods(http.MethodGet)
	// Start http server
	log.Fatal(http.ListenAndServe(":8000", router))
}
```

I went ahead and made the errors `const` variables in the global scope so we can use them anywhere we want without having to repeat ourselves, this is not necessary but it makes life a bit easier.
Let's look at a couple things that seem a bit odd.
First what's that `mux.Vars(r)`?
That's from `gorilla/mux` and one of the reasons we are using it.
It takes a request as an argument and can tell us a lot of stuff about that request.
The variable `params` is a type `map[string]string` which means that the key is a string and the value is a string.
If you've used dictionaries in Python I think it's pretty similar.
We give it the `ordernumber` key which is what we specified in `apiV1.HandleFunc("/delivery/{ordernumber}", GetDelivery).Methods(http.MethodGet)` and then use the `strconv` library to convert it from string to an integer.
Second, the `for` loop looks a bit weird, what's up with that `range deliveries`?
Using `range` we can iterate over something, in this case a slice (essentially a list).
This returns two variables, in this case one that is the key/index which we are ignoring by using `_` and the other one is the value `d` which is a single delivery from the list of deliveries we set up.
With all that out of the way, time to test it.
Run the server with `go run main.go` and visit `localhost:8000/api/v1/deliveries/2` to see the information about the second delivery returned.
Pretty good, right?
