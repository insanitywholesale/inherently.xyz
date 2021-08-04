---
title: "Go Api Part 3"
date: 2021-07-10T15:56:21+03:00
draft: true
summary: "Adding a database to a REST API in golang part 3"
tags: ["tutorial", "programming", "golang", "api", "database"]
---

# TODO
- fix api getdelivery (use notfound)
- fix links in prev relevant tut

## Previous relevant tutorial
The development of the CRUD REST API was described [in part 2]
and the introduction to the series can be found in [part 1] so read those first if you're new.

## Intro
After creating a minimally functional API, we're going to add persistent storage to it in the form of a database.
In this case it is going to be postgres running inside docker for ease of installation and use.

## Starting point
Here is where we left off last time:

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

// type deliveries is slice of Delivery pointers
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

// Create a new delivery
func AddDelivery(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	d := &Delivery{}
	// because deliveries start from 1
	orderNum := int(len(deliveries)) + 1
	err := json.NewDecoder(r.Body).Decode(d)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte(BadReq))
		return
	}
	// Override whatever the sender had sent
	d.OrderNumber = orderNum
	// Append the delivery to deliveries list
	deliveries = append(deliveries, d)
	w.WriteHeader(http.StatusCreated)
	// Send back the delivery that was saved
	json.NewEncoder(w).Encode(d)
	return
}

// Update an existing delivery
func UpdateDelivery(w http.ResponseWriter, r *http.Request) {
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
			err := json.NewDecoder(r.Body).Decode(d)
			if err != nil {
				w.WriteHeader(http.StatusBadRequest)
				w.Write([]byte(BadReq))
				return
			}
			d.OrderNumber = orderNum
			w.WriteHeader(http.StatusAccepted)
			json.NewEncoder(w).Encode(d)
			return
		}
	}
	w.WriteHeader(http.StatusNotFound)
	w.Write([]byte(NotFound))
	return
}

// Delete a delivery (not really)
func DeleteDelivery(w http.ResponseWriter, r *http.Request) {
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
			d.Cancelled = true
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
	apiV1.HandleFunc("/delivery", AddDelivery).Methods(http.MethodPost)
	apiV1.HandleFunc("/delivery/{ordernumber}", UpdateDelivery).Methods(http.MethodPut)
	apiV1.HandleFunc("/delivery/{ordernumber}", DeleteDelivery).Methods(http.MethodDelete)
	// Start http server
	log.Fatal(http.ListenAndServe(":8000", router))
}
```

## Restructuring
In my opinion a good first move is to abstract away the specifics of the database before moving further.
Some might see it as a premature optimization but I believe it's important to not mix the concerns of storing data with the API.
We will do that by having an interface that many different data storage backends can satisfy.
Initially we will remove the specifics of the simple list we used and make it more generalized.
Up until now all the code was in a single file and it's kind of crowded with data models, API routes, API functions and data storage so that will change.

### Important note
Since we will be splitting the contents of the `main` package over different files we won't be able to run our program using `go run main.go`.
All the `.go` files need to be included so the command should instead be `go run *.go`

### Models
First off let's cut and then paste the models in their own file called `models.go` next to `main.go` like so:

```go
package main

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
```

Simple enough I'd say.
Remember to delete the code from `main.go` otherwise the compiler will error out.
Next let's handle the API stuff.

### API
In a new file called `api.go` we will first copy the relevant functions and then do a little refactoring like renaming `main()` since we can't have two of them as well as making that function return something that can be easily used by the actual `main()` function.
In this case we'll just return the router and let the code in `main.go` handle what port it will run at.
Once again, remember to delete this code from `main.go` otherwise it won't run.

```go
package main

import (
	"encoding/json"
	"github.com/gorilla/mux"
	"net/http"
	"strconv"
)

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

// Create a new delivery
func AddDelivery(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	d := &Delivery{}
	// because deliveries start from 1
	orderNum := int(len(deliveries)) + 1
	err := json.NewDecoder(r.Body).Decode(d)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte(BadReq))
		return
	}
	// Override whatever the sender had sent
	d.OrderNumber = orderNum
	// Append the delivery to deliveries list
	deliveries = append(deliveries, d)
	w.WriteHeader(http.StatusCreated)
	// Send back the delivery that was saved
	json.NewEncoder(w).Encode(d)
	return
}

// Update an existing delivery
func UpdateDelivery(w http.ResponseWriter, r *http.Request) {
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
			err := json.NewDecoder(r.Body).Decode(d)
			if err != nil {
				w.WriteHeader(http.StatusBadRequest)
				w.Write([]byte(BadReq))
				return
			}
			d.OrderNumber = orderNum
			w.WriteHeader(http.StatusAccepted)
			json.NewEncoder(w).Encode(d)
			return
		}
	}
	w.WriteHeader(http.StatusNotFound)
	w.Write([]byte(NotFound))
	return
}

// Delete a delivery (not really)
func DeleteDelivery(w http.ResponseWriter, r *http.Request) {
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
			d.Cancelled = true
			json.NewEncoder(w).Encode(d)
			return
		}
	}
	w.WriteHeader(http.StatusNotFound)
	w.Write([]byte(NotFound))
	return
}

func MakeRouter() http.Handler {
	// Set up router
	router := mux.NewRouter()
	// Set up subrouter for api version 1
	apiV1 := router.PathPrefix("/api/v1").Subrouter()
	// Set up routes
	apiV1.HandleFunc("/deliveries", GetAllDeliveries).Methods(http.MethodGet)
	apiV1.HandleFunc("/delivery/{ordernumber}", GetDelivery).Methods(http.MethodGet)
	apiV1.HandleFunc("/delivery", AddDelivery).Methods(http.MethodPost)
	apiV1.HandleFunc("/delivery/{ordernumber}", UpdateDelivery).Methods(http.MethodPut)
	apiV1.HandleFunc("/delivery/{ordernumber}", DeleteDelivery).Methods(http.MethodDelete)
	return router
}
```

Looking nice and neat. We should probably tinker with `main.go` too though.

#### Main after API restructure
Let's adjust `main.go` to fit with the changes we've made.
The list stuff will still be there but the line count is greatly reduced:

```go
package main

import (
	"log"
	"net/http"
)

// type deliveries is slice of Delivery pointers
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

func main() {
	router := MakeRouter()
	log.Fatal(http.ListenAndServe(":8000", router))
}
```
Since we're cleaning things up and are planning to add a database, time to remove the list and put it in its own file.

### List Restructure
Our `main.go` is getting emptier so let's remove the list stuff and put it in its own file called `listdb.go`

```go
package main

// type deliveries is slice of Delivery pointers
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
```
Nice and easy, we radically reduced the code inside `main.go` and separated our code in nicely named files.

#### Main after list database restructure
Take a peek at `main.go` after all the changes.
You will notice that it is a lot shorter and only deals with running our API server and not much else:

```go
package main

import (
	"log"
	"net/http"
)

func main() {
	router := MakeRouter()
	log.Fatal(http.ListenAndServe(":8000", router))
}
```

## Database
This is a big addition so we'll have to think about it a little bit.
In my opinion a good first move is to abstract away the specifics of the database.
Some might see it as a premature optimization but I believe it's important to not mix the concerns of storing data with the API.
We will do that by having an interface that many different data storage backends can satisfy.

### Interface
The fake database we used in part 2 is mostly in its own file called `listdb.go` but there are still implementation-specific details of it inside `api.go`.
Before ripping out what exists, we'll define our interface. Due to what it is, it fits best inside `models.go`.
This is a simple interface of something that can essentially perform the same actions as the API except it only deals with talking to the database.
Take a look at what is in `models.go` now:
```go
package main

type DeliveryDB interface {
	ReturnAll() ([]*Delivery, error)
	ReturnOne(orderNumber int) (*Delivery, error)
	Store(*Delivery) (*Delivery, error)
	Change(orderNumber int, del *Delivery) (*Delivery, error)
	Remove(orderNumber int) error
}

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
```
Short and sweet, does what it should.
How do we use this abstraction though?
For this we'll need to move quite a few things out of `api.go` into `listdb.go`.

### Separating concerns
We will start by moving the things related to data storage out of `api.go` into `listdb.go`.
This will be done so we can implement the `DeliveryDB` interface.
Before the actual work, take a look at a shortened version of the data-related parts of `api.go`:
```go
// Read all deliveries
func GetAllDeliveries(w http.ResponseWriter, r *http.Request) {
	json.NewEncoder(w).Encode(deliveries)
}

// Read a specific delivery
func GetDelivery(w http.ResponseWriter, r *http.Request) {
	for _, d := range deliveries {
		if d.OrderNumber == orderNum {
			w.WriteHeader(http.StatusOK)
			json.NewEncoder(w).Encode(d)
			return
		}
	}
}

// Create a new delivery
func AddDelivery(w http.ResponseWriter, r *http.Request) {
	// Override whatever the sender had sent
	d.OrderNumber = orderNum
	// Append the delivery to deliveries list
	deliveries = append(deliveries, d)
}

// Update an existing delivery
func UpdateDelivery(w http.ResponseWriter, r *http.Request) {
	for _, d := range deliveries {
		if d.OrderNumber == orderNum {
			err := json.NewDecoder(r.Body).Decode(d)
			if err != nil {
				w.WriteHeader(http.StatusBadRequest)
				w.Write([]byte(BadReq))
				return
			}
			d.OrderNumber = orderNum
			w.WriteHeader(http.StatusAccepted)
			json.NewEncoder(w).Encode(d)
			return
		}
	}
}

// Delete a delivery (not really)
func DeleteDelivery(w http.ResponseWriter, r *http.Request) {
	for _, d := range deliveries {
		if d.OrderNumber == orderNum {
			w.WriteHeader(http.StatusOK)
			d.Cancelled = true
			json.NewEncoder(w).Encode(d)
			return
		}
	}
}
```
These is what we will grab and reshape to be the implementation of the `DeliveryDB` interface inside `listdb.go`.
The `ReturnAll`, `ReturnOne`, `Store`, `Change` and `Remove` functions should be implemented on a type, in this case, `deliveryList`.

#### List database
There isn't much more to say so here it is:
```go
package main

import (
	"errors"
)

// type deliveries is slice of Delivery pointers
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
		Cancelled:        false,
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
		Cancelled:        false,
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
		Cancelled:        true,
		Delivered:        false,
		DeliveryAttempts: 24,
		Driver: DeliveryDriver{
			FirstName: "Pilotos",
			LastName:  "Aeroplanou",
		},
	},
}

func NewListDatabase() deliveryList {
	return deliveries
}

func (dl deliveryList) ReturnAll() ([]*Delivery, error) {
	return deliveries, nil
}

func (dl deliveryList) ReturnOne(orderNumber int) (*Delivery, error) {
	for _, d := range deliveries {
		if d.OrderNumber == orderNumber {
			return d, nil
		}
	}
	return nil, errors.New(NotFound)
}

func (dl deliveryList) Store(d *Delivery) (*Delivery, error) {
	d.OrderNumber = int(len(deliveries))
	deliveries = append(deliveries, d)
	return d, nil
}

func (dl deliveryList) Change(orderNumber int, del *Delivery) (*Delivery, error) {
	for _, d := range deliveries {
		if d.OrderNumber == orderNumber {
			del.OrderNumber = orderNumber
			d = del
			return d, nil
		}
	}
	return nil, errors.New(NotFound)
}

func (dl deliveryList) Remove(orderNumber int) error {
	for _, d := range deliveries {
		if d.OrderNumber == orderNumber {
			d.Cancelled = true
			return nil
		}
	}
	return errors.New(NotFound)
}
```
We've moved everything related to data-handling out of the API code and have a mock database to work with.
Obviously it's only in memory so if we stop and restart the application any changes made to the data isn't saved anywhere.

#### Refactor API code
<!-- TODO: rewrite API code to use abstracted db-->
Before moving on to implementing a different database let's change the API code to use the generalized interface.
I also changed a couple stuff related to HTTP error codes because some were incorrect and some because most clients expect a 200 response if a request is successful.
At any rate, let's look at the refactored `api.go`:
```go
package main

import (
	"encoding/json"
	"github.com/gorilla/mux"
	"net/http"
	"strconv"
)

// Constant for Bad Request
const BadReq string = `{"error": "bad request"}`

// Constant for Not Found
const NotFound string = `{"error": "not found"}`

// Read all deliveries
func GetAllDeliveries(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	dels, err := deliverydb.ReturnAll()
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte(BadReq))
		return
	}
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(dels)
	return
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
	del, err := deliverydb.ReturnOne(orderNum)
	if err != nil {
		w.WriteHeader(http.StatusNotFound)
		w.Write([]byte(err.Error()))
		return
	}
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(del)
	return
}

// Create a new delivery
func AddDelivery(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	d := &Delivery{}
	err := json.NewDecoder(r.Body).Decode(d)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte(BadReq))
		return
	}
	del, err := deliverydb.Store(d)
	if err != nil {
		w.WriteHeader(http.StatusNotFound)
		w.Write([]byte(err.Error()))
		return
	}
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(del)
	return
}

// Update an existing delivery
func UpdateDelivery(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	params := mux.Vars(r)
	orderNum, err := strconv.Atoi(params["ordernumber"])
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte(BadReq))
		return
	}
	d := &Delivery{}
	err = json.NewDecoder(r.Body).Decode(d)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte(BadReq))
		return
	}
	del, err := deliverydb.Change(orderNum, d)
	if err != nil {
		w.WriteHeader(http.StatusNotFound)
		w.Write([]byte(NotFound))
		return
	}
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(del)
	return
}

// Delete a delivery (not really)
func DeleteDelivery(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	params := mux.Vars(r)
	orderNum, err := strconv.Atoi(params["ordernumber"])
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte(BadReq))
		return
	}
	err = deliverydb.Remove(orderNum)
	if err != nil {
		w.WriteHeader(http.StatusNotFound)
		w.Write([]byte(NotFound))
		return
	}
	w.WriteHeader(http.StatusOK)
	return
}

func makeRouter() http.Handler {
	// Set up router
	router := mux.NewRouter()
	// Set up subrouter for api version 1
	apiV1 := router.PathPrefix("/api/v1").Subrouter()
	// Set up routes
	apiV1.HandleFunc("/deliveries", GetAllDeliveries).Methods(http.MethodGet)
	apiV1.HandleFunc("/delivery/{ordernumber}", GetDelivery).Methods(http.MethodGet)
	apiV1.HandleFunc("/delivery", AddDelivery).Methods(http.MethodPost)
	apiV1.HandleFunc("/delivery/{ordernumber}", UpdateDelivery).Methods(http.MethodPut)
	apiV1.HandleFunc("/delivery/{ordernumber}", DeleteDelivery).Methods(http.MethodDelete)
	return router
}
```

And here is `main.go` where the `DeliveryDB` is initialized:

```go
package main

import (
	"log"
	"net/http"
)

var deliverydb DeliveryDB

func main() {
	// Create a database
	deliverydb = NewListDatabase()
	// Start http server
	router := makeRouter()
	log.Fatal(http.ListenAndServe(":8000", router))
}
```

### Postgres
There are lots of databases out there but for the purposes of this tutorial I chose postgres.
It's essentially the only one out of the traditional RDBMS systems worth using.
The Go standard library is pretty rich so there is a `database/sql` package although we have to provide a database driver to it.
The two most popular drivers for postgres are [pq](https://github.com/lib/pq) and [pgx](github.com/jackc/pgx).
Since pq is in maintenance mode and pgx is the recommended alternative by the pq authors we'll go with that.
The [guide on the pgx wiki](https://github.com/jackc/pgx/wiki/Getting-started-with-pgx-through-database-sql) is a great starting point but we'll add a big more to it.

#### Connection code
Enough rambling, let's see how we can start using postgres.
Create a file called `postgres.go` with the following contents:
```go
package main

import (
	"database/sql"
	_ "github.com/jackc/pgx/v4/stdlib"
)

type postgresDB struct {
	client *sql.DB
	pgURL  string
}

func newPostgresClient(url string) (*sql.DB, error) {
	client, err := sql.Open("pgx", url)
	if err != nil {
		return nil, err
	}
	err = client.Ping()
	if err != nil {
		return nil, err
	}
	return client, nil
}

func NewPostgresDB(url string) (*postgresDB, error) {
	pgclient, err := newPostgresClient(url)
	if err != nil {
		return nil, err
	}
	db := &postgresDB{
		pgURL:  url,
		client: pgclient,
	}
	return db, nil
}

func (pdb *postgresDB) ReturnAll() ([]*Delivery, error) {
	return []*Delivery{}, nil
}

func (pdb *postgresDB) ReturnOne(orderNumber int) (*Delivery, error) {
	return &Delivery{}, nil
}

func (pdb *postgresDB) Store(d *Delivery) (*Delivery, error) {
	return &Delivery{}, nil
}

func (pdb *postgresDB) Change(orderNumber int, del *Delivery) (*Delivery, error) {
	return &Delivery{}, nil
}

func (pdb *postgresDB) Remove(orderNumber int) error {
	return nil
}

```
Quite a few stuff going on.
First up, the imports.
As discussed we can use `database/sql` from the standard library and then combine it with a driver.
The line `_ "github.com/jackc/pgx/v4/stdlib"` means that we're importing that dependency but we won't have to write `stdlib.Something` to use its functions and variables but instead just write `Something`.
Following that we have the `postgresDB` struct which will implement the `DeliveryDB` interface and which stores the database URL and the database client that uses that URL.
Next up, there is the initialization code which is split into two functions, one private and one public as indicated by the lowercase/uppercase letter.
The private function, named `newPostgresClient` creates a client for the database through `sql.Open` using the `pgx` driver and then pings the database to make sure it's accessible.
The public function runs `newPostgresClient` with the provided URL and if there are no errors it saves the URL as well as the client to a new instance of `postgresDB` and returns it to the caller.
Last but not least we see that `ReturnAll`, `ReturnOne`, `Store`, `Change` and `Remove` methods are implemented on the `postgresDB` struct as indicated by `(pdb *postgresDB)`.
Right now they don't really do anything, they're there just so the `DeliveryDB` interface is satisfied and the compiler doesn't exit with an error.

#### Choose database
Now that we have written code to connect to postgres, we should probably set it up in `main.go` so if the environment variable `PG_URL` is set, we use that connection string to connect to postgres.

```go
package main

import (
	"log"
	"net/http"
	"os"
)

var deliverydb DeliveryDB

func main() {
	// Create a database
	pgURL := os.Getenv("PG_URL")
	if pgURL != "" {
		db, err := NewPostgresDB(pgURL)
		if err != nil {
			log.Fatalf("error with postgres connection %v", err)
		}
		deliverydb = db
		log.Println("connected to postgres")
	} else {
		deliverydb = NewListDatabase()
		log.Println("connected to listdb")
	}
	// Start http server
	router := makeRouter()
	log.Fatal(http.ListenAndServe(":8000", router))
}
```
It's pretty simple, we get the value of the `PG_URL` variable and if it's not empty, we use it to connect to postgres.
If it's empty we just use the fake list database instead so our web service can still run.

#### Test connection
While we are confident that we did everything right, it doesn't hurt to test it out.
Using docker we can quickly create a test database without permanently storing any data.
The following command should bring up a database we can use for testing:
```bash
docker run -d --rm --name testpostgres -p 5432:5432 -e POSTGRES_PASSWORD=Apasswd -e POSTGRES_USER=tester postgres:latest
```
After it's done, set the `PG_URL` environment variable like so:
```bash
export PG_URL="postgresql://tester:Apasswd@localhost:5432?sslmode=disable"
```
And then run the service the same way we've been doing all along:
```bash
go run *.go
```
The message `connected to postgres` should appear in the command line.
And there we go, our connection is working and we can move on.
Kill the running database with:
```bash
docker stop testpostgres
```
And let's see how to write some SQL queries.

### Queries
In order to work with the database we will need to write queries to be used.
For the sake of simplicity we won't deduplicate the delivery drivers but that is something you could do in case you're looking for ways to tweak the project on your own.
With that in mind, what queries are we going to need?
One per method of the delivery database interface should be enough, along with one to create the table on first run.

#### Create table query
Let's begin then by creating a file called `queries.go` with the create table query:
```go
package main

var createDeliveriesTableQuery = `CREATE TABLE IF NOT EXISTS Deliveries (
	OrderNumber SERIAL PRIMARY KEY,
	City VARCHAR,
	Zipcode VARCHAR,
	Address VARCHAR,
	Phone1 VARCHAR,
	Phone2 VARCHAR,
	Cancelled BOOL,
	Delivered BOOL,
	DeliveryAttempts INTEGER,
	DriverFirstName VARCHAR,
	DriverLastName VARCHAR
);`
```
This is an SQL representation of our `Delivery` model.
One thing you might not have seen is `SERIAL PRIMARY KEY`.
It will automatically increment when a new entry is inserted so we don't have to keep track of it ourselves.
Let's incorporate this query into the `postgres.go` code:
```go
package main

import (
	"database/sql"
	_ "github.com/jackc/pgx/v4/stdlib"
)

type postgresDB struct {
	client *sql.DB
	pgURL  string
}

func newPostgresClient(url string) (*sql.DB, error) {
	client, err := sql.Open("pgx", url)
	if err != nil {
		return nil, err
	}
	err = client.Ping()
	if err != nil {
		return nil, err
	}
	_, err = client.Exec(createDeliveriesTableQuery)
	if err != nil {
		return nil, err
	}
	return client, nil
}

func NewPostgresDB(url string) (*postgresDB, error) {
	pgclient, err := newPostgresClient(url)
	if err != nil {
		return nil, err
	}
	db := &postgresDB{
		pgURL:  url,
		client: pgclient,
	}
	return db, nil
}

func (pdb *postgresDB) ReturnAll() ([]*Delivery, error) {
	return []*Delivery{}, nil
}

func (pdb *postgresDB) ReturnOne(orderNumber int) (*Delivery, error) {
	return &Delivery{}, nil
}

func (pdb *postgresDB) Store(d *Delivery) (*Delivery, error) {
	return &Delivery{}, nil
}

func (pdb *postgresDB) Change(orderNumber int, del *Delivery) (*Delivery, error) {
	return &Delivery{}, nil
}

func (pdb *postgresDB) Remove(orderNumber int) error {
	return nil
}
```
Just 4 new lines and our database will be set up on first connection.
You can run the connection test again as we did in the previous section.

#### See all deliveries
This requires a simple query, we just select everything in the `Deliveries` table so take a loot at `queries.go`:
```go
package main

var createDeliveriesTableQuery = `CREATE TABLE IF NOT EXISTS Deliveries (
	OrderNumber SERIAL PRIMARY KEY,
	City VARCHAR,
	Zipcode VARCHAR,
	Address VARCHAR,
	Phone1 VARCHAR,
	Phone2 VARCHAR,
	Cancelled BOOL,
	Delivered BOOL,
	DeliveryAttempts INTEGER,
	DriverFirstName VARCHAR,
	DriverLastName VARCHAR
);`
var retrieveAllDeliveriesQuery = `SELECT 
	OrderNumber,
	City,
	Zipcode,
	Address,
	Phone1,
	Phone2,
	Cancelled,
	Delivered,
	DeliveryAttempts,
	DriverFirstName,
	DriverLastName FROM Deliveries;`
```
And then we'll use it in the `ReturnAll` method inside `postgres.go`
```go
package main

import (
	"database/sql"
	_ "github.com/jackc/pgx/v4/stdlib"
)

type postgresDB struct {
	client *sql.DB
	pgURL  string
}

func newPostgresClient(url string) (*sql.DB, error) {
	client, err := sql.Open("pgx", url)
	if err != nil {
		return nil, err
	}
	err = client.Ping()
	if err != nil {
		return nil, err
	}
	_, err = client.Exec(createDeliveriesTableQuery)
	if err != nil {
		return nil, err
	}
	return client, nil
}

func NewPostgresDB(url string) (*postgresDB, error) {
	pgclient, err := newPostgresClient(url)
	if err != nil {
		return nil, err
	}
	db := &postgresDB{
		pgURL:  url,
		client: pgclient,
	}
	return db, nil
}

func (pdb *postgresDB) ReturnAll() ([]*Delivery, error) {
	var deliveryslice = []*Delivery{}
	rows, err := pdb.client.Query(retrieveAllDeliveriesQuery)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var delivery = &Delivery{}
		err = rows.Scan(
			&delivery.OrderNumber,
			&delivery.City,
			&delivery.Zipcode,
			&delivery.Address,
			&delivery.Phone1,
			&delivery.Phone2,
			&delivery.Cancelled,
			&delivery.Delivered,
			&delivery.DeliveryAttempts,
			&delivery.Driver.FirstName,
			&delivery.Driver.LastName,
		)
		if err != nil {
			return nil, err
		}
		deliveryslice = append(deliveryslice, delivery)
	}
	return deliveryslice, nil
}

func (pdb *postgresDB) ReturnOne(orderNumber int) (*Delivery, error) {
	return &Delivery{}, nil
}

func (pdb *postgresDB) Store(d *Delivery) (*Delivery, error) {
	return &Delivery{}, nil
}

func (pdb *postgresDB) Change(orderNumber int, del *Delivery) (*Delivery, error) {
	return &Delivery{}, nil
}

func (pdb *postgresDB) Remove(orderNumber int) error {
	return nil
}
```
Initially, we create an empty list of deliveries to store all the deliveries retrieved from the database.
Then we run the query, iterate over the rows returned, save the results to the delivery struct and append that struct to the list.
Finally we return the list to the caller and that's all.

#### See one delivery
This one is also pretty simple, we select everything if the entry has the specified order number:
```go
package main

var createDeliveriesTableQuery = `CREATE TABLE IF NOT EXISTS Deliveries (
	OrderNumber SERIAL PRIMARY KEY,
	City VARCHAR,
	Zipcode VARCHAR,
	Address VARCHAR,
	Phone1 VARCHAR,
	Phone2 VARCHAR,
	Cancelled BOOL,
	Delivered BOOL,
	DeliveryAttempts INTEGER,
	DriverFirstName VARCHAR,
	DriverLastName VARCHAR
);`
var retrieveAllDeliveriesQuery = `SELECT 
	OrderNumber,
	City,
	Zipcode,
	Address,
	Phone1,
	Phone2,
	Cancelled,
	Delivered,
	DeliveryAttempts,
	DriverFirstName,
	DriverLastName FROM Deliveries;`
var retrieveOneDeliveryQuery = `SELECT
	OrderNumber,
	City,
	Zipcode,
	Address,
	Phone1,
	Phone2,
	Cancelled,
	Delivered,
	DeliveryAttempts,
	DriverFirstName,
	DriverLastName
FROM Deliveries WHERE OrderNumber=$1;`
```
And now we need to use it inside our `ReturnOne` method:
```go
package main

import (
	"database/sql"
	_ "github.com/jackc/pgx/v4/stdlib"
)

type postgresDB struct {
	client *sql.DB
	pgURL  string
}

func newPostgresClient(url string) (*sql.DB, error) {
	client, err := sql.Open("pgx", url)
	if err != nil {
		return nil, err
	}
	err = client.Ping()
	if err != nil {
		return nil, err
	}
	_, err = client.Exec(createDeliveriesTableQuery)
	if err != nil {
		return nil, err
	}
	return client, nil
}

func NewPostgresDB(url string) (*postgresDB, error) {
	pgclient, err := newPostgresClient(url)
	if err != nil {
		return nil, err
	}
	db := &postgresDB{
		pgURL:  url,
		client: pgclient,
	}
	return db, nil
}

func (pdb *postgresDB) ReturnAll() ([]*Delivery, error) {
	var deliveryslice = []*Delivery{}
	row, err := pdb.client.Query(retrieveOneDeliveryQuery, orderNumber)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var delivery = &Delivery{}
		err = rows.Scan(
			&delivery.OrderNumber,
			&delivery.City,
			&delivery.Zipcode,
			&delivery.Address,
			&delivery.Phone1,
			&delivery.Phone2,
			&delivery.Cancelled,
			&delivery.Delivered,
			&delivery.DeliveryAttempts,
			&delivery.Driver.FirstName,
			&delivery.Driver.LastName,
		)
		if err != nil {
			return nil, err
		}
		deliveryslice = append(deliveryslice, delivery)
	}
	return deliveryslice, nil
}

func (pdb *postgresDB) ReturnOne(orderNumber int) (*Delivery, error) {
	var delivery = &Delivery{}
	row, err := pdb.client.Query(retrieveOneDeliveryQuery)
	if err != nil {
		return nil, err
	}
	err = row.Scan(
		&delivery.OrderNumber,
		&delivery.City,
		&delivery.Zipcode,
		&delivery.Address,
		&delivery.Phone1,
		&delivery.Phone2,
		&delivery.Cancelled,
		&delivery.Delivered,
		&delivery.DeliveryAttempts,
		&delivery.Driver.FirstName,
		&delivery.Driver.LastName,
	)
	return delivery, nil
}

func (pdb *postgresDB) Store(d *Delivery) (*Delivery, error) {
	return &Delivery{}, nil
}

func (pdb *postgresDB) Change(orderNumber int, del *Delivery) (*Delivery, error) {
	return &Delivery{}, nil
}

func (pdb *postgresDB) Remove(orderNumber int) error {
	return nil
}
```
This is basically the same as `ReturnAll` but even simpler so I won't cover it in detail.

#### Add one delivery
In order to test the retrieve methods, we need to have a way to store stuff first.
Since the database generates the order number, the query needs to return it when we run it.
```go
package main

var createDeliveriesTableQuery = `CREATE TABLE IF NOT EXISTS Deliveries (
	OrderNumber SERIAL PRIMARY KEY,
	City VARCHAR,
	Zipcode VARCHAR,
	Address VARCHAR,
	Phone1 VARCHAR,
	Phone2 VARCHAR,
	Cancelled BOOL,
	Delivered BOOL,
	DeliveryAttempts INTEGER,
	DriverFirstName VARCHAR,
	DriverLastName VARCHAR
);`
var retrieveAllDeliveriesQuery = `SELECT 
	OrderNumber,
	City,
	Zipcode,
	Address,
	Phone1,
	Phone2,
	Cancelled,
	Delivered,
	DeliveryAttempts,
	DriverFirstName,
	DriverLastName FROM Deliveries;`
var retrieveOneDeliveryQuery = `SELECT
	OrderNumber,
	City,
	Zipcode,
	Address,
	Phone1,
	Phone2,
	Cancelled,
	Delivered,
	DeliveryAttempts,
	DriverFirstName,
	DriverLastName
FROM Deliveries WHERE OrderNumber=$1;`
var storeDeliveryQuery = `INSERT INTO Deliveries (
	City,
	Zipcode,
	Address,
	Phone1,
	Phone2,
	Cancelled,
	Delivered,
	DeliveryAttempts,
	DriverFirstName,
	DriverLastName
) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) RETURNING OrderNumber;`
```
This way when we insert an entry, we will get back its order number.
Let's see how the `Store` method will be implemented
```go
package main

import (
	"database/sql"
	_ "github.com/jackc/pgx/v4/stdlib"
)

type postgresDB struct {
	client *sql.DB
	pgURL  string
}

func newPostgresClient(url string) (*sql.DB, error) {
	client, err := sql.Open("pgx", url)
	if err != nil {
		return nil, err
	}
	err = client.Ping()
	if err != nil {
		return nil, err
	}
	_, err = client.Exec(createDeliveriesTableQuery)
	if err != nil {
		return nil, err
	}
	return client, nil
}

func NewPostgresDB(url string) (*postgresDB, error) {
	pgclient, err := newPostgresClient(url)
	if err != nil {
		return nil, err
	}
	db := &postgresDB{
		pgURL:  url,
		client: pgclient,
	}
	return db, nil
}

func (pdb *postgresDB) ReturnAll() ([]*Delivery, error) {
	var deliveryslice = []*Delivery{}
	rows, err := pdb.client.Query(retrieveAllDeliveriesQuery)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var delivery = &Delivery{}
		err = rows.Scan(
			&delivery.OrderNumber,
			&delivery.City,
			&delivery.Zipcode,
			&delivery.Address,
			&delivery.Phone1,
			&delivery.Phone2,
			&delivery.Cancelled,
			&delivery.Delivered,
			&delivery.DeliveryAttempts,
			&delivery.Driver.FirstName,
			&delivery.Driver.LastName,
		)
		if err != nil {
			return nil, err
		}
		deliveryslice = append(deliveryslice, delivery)
	}
	return deliveryslice, nil
}

func (pdb *postgresDB) ReturnOne(orderNumber int) (*Delivery, error) {
	var delivery = &Delivery{}
	row, err := pdb.client.Query(retrieveOneDeliveryQuery, orderNumber)
	if err != nil {
		return nil, err
	}
	err = row.Scan(
		&delivery.OrderNumber,
		&delivery.City,
		&delivery.Zipcode,
		&delivery.Address,
		&delivery.Phone1,
		&delivery.Phone2,
		&delivery.Cancelled,
		&delivery.Delivered,
		&delivery.DeliveryAttempts,
		&delivery.Driver.FirstName,
		&delivery.Driver.LastName,
	)
	return delivery, nil
}

func (pdb *postgresDB) Store(d *Delivery) (*Delivery, error) {
	err := pdb.client.QueryRow(storeDeliveryQuery,
		d.City,
		d.Zipcode,
		d.Address,
		d.Phone1,
		d.Phone2,
		d.Cancelled,
		d.Delivered,
		d.DeliveryAttempts,
		d.Driver.FirstName,
		d.Driver.LastName,
	).Scan(&d.OrderNumber)
	if err != nil {
		return nil, err
	}
	return d, nil
}

func (pdb *postgresDB) Change(orderNumber int, del *Delivery) (*Delivery, error) {
	return &Delivery{}, nil
}

func (pdb *postgresDB) Remove(orderNumber int) error {
	return nil
}
```
In this method we just insert what the user sent, ignoring the order number they specified, and then return the entry as it was saved.

#### Update delivery
There are a few ways to go about updating existing entries.
We can check each thing about the `Delivery` that is sent to us and update only the things that are changed.
Another alternative is to swap out all existing values with what is sent which is the dumb method.
The first option allows for sending less data and maybe saving some bandwidth but the second one is easier to implement so we'll hope whoever uses our API does so responsibly.
Below is `queries.go` with our update query added.
Note that I used some different SQL syntax this time to keep it a little interesting:
```go
package main

var createDeliveriesTableQuery = `CREATE TABLE IF NOT EXISTS Deliveries (
	OrderNumber SERIAL PRIMARY KEY,
	City VARCHAR,
	Zipcode VARCHAR,
	Address VARCHAR,
	Phone1 VARCHAR,
	Phone2 VARCHAR,
	Cancelled BOOL,
	Delivered BOOL,
	DeliveryAttempts INTEGER,
	DriverFirstName VARCHAR,
	DriverLastName VARCHAR
);`
var retrieveAllDeliveriesQuery = `SELECT 
	OrderNumber,
	City,
	Zipcode,
	Address,
	Phone1,
	Phone2,
	Cancelled,
	Delivered,
	DeliveryAttempts,
	DriverFirstName,
	DriverLastName FROM Deliveries;`
var retrieveOneDeliveryQuery = `SELECT
	OrderNumber,
	City,
	Zipcode,
	Address,
	Phone1,
	Phone2,
	Cancelled,
	Delivered,
	DeliveryAttempts,
	DriverFirstName,
	DriverLastName
FROM Deliveries WHERE OrderNumber=$1;`
var storeDeliveryQuery = `INSERT INTO Deliveries (
	City,
	Zipcode,
	Address,
	Phone1,
	Phone2,
	Cancelled,
	Delivered,
	DeliveryAttempts,
	DriverFirstName,
	DriverLastName
) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) RETURNING OrderNumber;`
var changeDeliveryQuery = `UPDATE Deliveries SET
	City=$2,
	Zipcode=$3,
	Address=$4,
	Phone1=$5,
	Phone2=$6,
	Cancelled=$7,
	Delivered=$8,
	DeliveryAttempts=$9,
	DriverFirstName=$10
	DriverLastName=$11
WHERE OrderNumber=$1;`
```
Not too bad I'd say, we just set the values given if the entry has the order number given.
Using this in postgres is not too hard since we've seen the previous ones, give it a look:
```go
package main

import (
	"database/sql"
	_ "github.com/jackc/pgx/v4/stdlib"
)

type postgresDB struct {
	client *sql.DB
	pgURL  string
}

func newPostgresClient(url string) (*sql.DB, error) {
	client, err := sql.Open("pgx", url)
	if err != nil {
		return nil, err
	}
	err = client.Ping()
	if err != nil {
		return nil, err
	}
	_, err = client.Exec(createDeliveriesTableQuery)
	if err != nil {
		return nil, err
	}
	return client, nil
}

func NewPostgresDB(url string) (*postgresDB, error) {
	pgclient, err := newPostgresClient(url)
	if err != nil {
		return nil, err
	}
	db := &postgresDB{
		pgURL:  url,
		client: pgclient,
	}
	return db, nil
}

func (pdb *postgresDB) ReturnAll() ([]*Delivery, error) {
	var deliveryslice = []*Delivery{}
	rows, err := pdb.client.Query(retrieveAllDeliveriesQuery)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var delivery = &Delivery{}
		err = rows.Scan(
			&delivery.OrderNumber,
			&delivery.City,
			&delivery.Zipcode,
			&delivery.Address,
			&delivery.Phone1,
			&delivery.Phone2,
			&delivery.Cancelled,
			&delivery.Delivered,
			&delivery.DeliveryAttempts,
			&delivery.Driver.FirstName,
			&delivery.Driver.LastName,
		)
		if err != nil {
			return nil, err
		}
		deliveryslice = append(deliveryslice, delivery)
	}
	return deliveryslice, nil
}

func (pdb *postgresDB) ReturnOne(orderNumber int) (*Delivery, error) {
	var delivery = &Delivery{}
	row, err := pdb.client.Query(retrieveOneDeliveryQuery, orderNumber)
	if err != nil {
		return nil, err
	}
	err = row.Scan(
		&delivery.OrderNumber,
		&delivery.City,
		&delivery.Zipcode,
		&delivery.Address,
		&delivery.Phone1,
		&delivery.Phone2,
		&delivery.Cancelled,
		&delivery.Delivered,
		&delivery.DeliveryAttempts,
		&delivery.Driver.FirstName,
		&delivery.Driver.LastName,
	)
	return delivery, nil
}

func (pdb *postgresDB) Store(d *Delivery) (*Delivery, error) {
	err := pdb.client.QueryRow(storeDeliveryQuery,
		d.City,
		d.Zipcode,
		d.Address,
		d.Phone1,
		d.Phone2,
		d.Cancelled,
		d.Delivered,
		d.DeliveryAttempts,
		d.Driver.FirstName,
		d.Driver.LastName,
	).Scan(&d.OrderNumber)
	if err != nil {
		return nil, err
	}
	return d, nil
}

func (pdb *postgresDB) Change(orderNumber int, del *Delivery) (*Delivery, error) {
	err := pdb.client.Exec(changeDeliveryQuery,
		orderNumber,
		del.City,
		del.Zipcode,
		del.Address,
		del.Phone1,
		del.Phone2,
		del.Cancelled,
		del.Delivered,
		del.DeliveryAttempts,
		del.Driver.FirstName,
		del.Driver.LastName,
	)
	if err != nil {
		return nil, err
	}
	return pdb.ReturnOne(orderNumber)
}

func (pdb *postgresDB) Remove(orderNumber int) error {
	return nil
}
```
As you can see we don't use the order number from the delivery object since the user might have maliciously changed it.
In addition, `ReturnOne` is called to make sure that we send back the changed entry as it is in the database so there is no data discrepancies between what we store and what we show.

#### Delete delivery
If you remember, we don't actually delete deliveries, we just set the `Cancelled` status to `true`.
However for the sake of showing how the query would be, I'll include another one along with its usage inside prostgres as comments alongside the proper one.
```go
package main

var createDeliveriesTableQuery = `CREATE TABLE IF NOT EXISTS Deliveries (
	OrderNumber SERIAL PRIMARY KEY,
	City VARCHAR,
	Zipcode VARCHAR,
	Address VARCHAR,
	Phone1 VARCHAR,
	Phone2 VARCHAR,
	Cancelled BOOL,
	Delivered BOOL,
	DeliveryAttempts INTEGER,
	DriverFirstName VARCHAR,
	DriverLastName VARCHAR
);`
var retrieveAllDeliveriesQuery = `SELECT 
	OrderNumber,
	City,
	Zipcode,
	Address,
	Phone1,
	Phone2,
	Cancelled,
	Delivered,
	DeliveryAttempts,
	DriverFirstName,
	DriverLastName FROM Deliveries;`
var retrieveOneDeliveryQuery = `SELECT
	OrderNumber,
	City,
	Zipcode,
	Address,
	Phone1,
	Phone2,
	Cancelled,
	Delivered,
	DeliveryAttempts,
	DriverFirstName,
	DriverLastName
FROM Deliveries WHERE OrderNumber=$1;`
var storeDeliveryQuery = `INSERT INTO Deliveries (
	City,
	Zipcode,
	Address,
	Phone1,
	Phone2,
	Cancelled,
	Delivered,
	DeliveryAttempts,
	DriverFirstName,
	DriverLastName
) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) RETURNING OrderNumber;`
var changeDeliveryQuery = `UPDATE Deliveries SET
	City=$2,
	Zipcode=$3,
	Address=$4,
	Phone1=$5,
	Phone2=$6,
	Cancelled=$7,
	Delivered=$8,
	DeliveryAttempts=$9,
	DriverFirstName=$10
	DriverLastName=$11
WHERE OrderNumber=$1;`
var removeDeliveryQuery = `UPDATE Deliveries SET Cancelled=true WHERE OrderNumber=$1`
//commented out so the compiler doesn't complain about unused variables
//var removeDeliveryForRealQuery = `DELETE FROM Deliveries WHERE OrderNumber=$1`
```
The query we'll use is another update, this time it simply sets the `Cancelled` field to `true`.
Here is the postgres part of it:
```go
package main

import (
	"database/sql"
	_ "github.com/jackc/pgx/v4/stdlib"
)

type postgresDB struct {
	client *sql.DB
	pgURL  string
}

func newPostgresClient(url string) (*sql.DB, error) {
	client, err := sql.Open("pgx", url)
	if err != nil {
		return nil, err
	}
	err = client.Ping()
	if err != nil {
		return nil, err
	}
	_, err = client.Exec(createDeliveriesTableQuery)
	if err != nil {
		return nil, err
	}
	return client, nil
}

func NewPostgresDB(url string) (*postgresDB, error) {
	pgclient, err := newPostgresClient(url)
	if err != nil {
		return nil, err
	}
	db := &postgresDB{
		pgURL:  url,
		client: pgclient,
	}
	return db, nil
}

func (pdb *postgresDB) ReturnAll() ([]*Delivery, error) {
	var deliveryslice = []*Delivery{}
	rows, err := pdb.client.Query(retrieveAllDeliveriesQuery)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var delivery = &Delivery{}
		err = rows.Scan(
			&delivery.OrderNumber,
			&delivery.City,
			&delivery.Zipcode,
			&delivery.Address,
			&delivery.Phone1,
			&delivery.Phone2,
			&delivery.Cancelled,
			&delivery.Delivered,
			&delivery.DeliveryAttempts,
			&delivery.Driver.FirstName,
			&delivery.Driver.LastName,
		)
		if err != nil {
			return nil, err
		}
		deliveryslice = append(deliveryslice, delivery)
	}
	return deliveryslice, nil
}

func (pdb *postgresDB) ReturnOne(orderNumber int) (*Delivery, error) {
	var delivery = &Delivery{}
	row, err := pdb.client.Query(retrieveOneDeliveryQuery, orderNumber)
	if err != nil {
		return nil, err
	}
	err = row.Scan(
		&delivery.OrderNumber,
		&delivery.City,
		&delivery.Zipcode,
		&delivery.Address,
		&delivery.Phone1,
		&delivery.Phone2,
		&delivery.Cancelled,
		&delivery.Delivered,
		&delivery.DeliveryAttempts,
		&delivery.Driver.FirstName,
		&delivery.Driver.LastName,
	)
	return delivery, nil
}

func (pdb *postgresDB) Store(d *Delivery) (*Delivery, error) {
	err := pdb.client.QueryRow(storeDeliveryQuery,
		d.City,
		d.Zipcode,
		d.Address,
		d.Phone1,
		d.Phone2,
		d.Cancelled,
		d.Delivered,
		d.DeliveryAttempts,
		d.Driver.FirstName,
		d.Driver.LastName,
	).Scan(&d.OrderNumber)
	if err != nil {
		return nil, err
	}
	return d, nil
}

func (pdb *postgresDB) Change(orderNumber int, del *Delivery) (*Delivery, error) {
	err := pdb.client.Exec(changeDeliveryQuery,
		orderNumber,
		del.City,
		del.Zipcode,
		del.Address,
		del.Phone1,
		del.Phone2,
		del.Cancelled,
		del.Delivered,
		del.DeliveryAttempts,
		del.Driver.FirstName,
		del.Driver.LastName,
	)
	if err != nil {
		return nil, err
	}
	return pdb.ReturnOne(orderNumber)
}

func (pdb *postgresDB) Remove(orderNumber int) error {
	err := pdb.client.Exec(removeDeliveryQuery, orderNumber)
	if err != nil {
		return err
	}
	return nil
}
```
Just pass the order number and execute the query.
Simple enough.
