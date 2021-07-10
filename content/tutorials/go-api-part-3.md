---
title: "Go Api Part 3"
date: 2021-07-10T15:56:21+03:00
draft: true
tags: ["tutorial", "programming", "golang", "api", "database"]
---

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

### Models
First off let's put the models in their own file called `models.go` next to `main.go` like so:

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
Next let's handle the API stuff.

### API
In a new file called `api.go` we will first copy the relevant functions and then do a little refactoring like renaming `main()` since we can't have two of them as well as making that function return something that can be easily used by the actual `main()` function.
In this case we'll just return the router and let the code in `main.go` handle what port it will run at.

```go
package main

import (
	"encoding/json"
	"github.com/gorilla/mux"
	"net/http"
	"strconv"
)

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

Looking good.
While we're cleaning things up and are planning to add a database, time to remove the list and put it in its own file.

### List
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

Nice and easy, we've greatly reduced the code inside `main.go` and separated our code in nicely named files.

### Main
However we should adjust `main.go` to fit with the changes we've made.
You will notice that it is a lot shorter and only deals with running our API server and not much else:

```go
package main

import (
	"net/http"
	"log"
)

func main() {
	// Start http server
	router := makeRouter()
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
	GetAll() ([]Delivery, error)
	GetOne(orderNumber int) (Delivery, error)
	Store(Delivery) error
	Change(orderNumber int) error
	Remove(orderNumber) error
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

### Abstracting
We will start by moving the things related to data storage out of `api.go` into `listdb.go`.
This will be done so we can implement the `DeliveryDB` interface.
Here is the current state of the file:

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

Now for the actual work, here is a shortened version of the data-related parts of `api.go`:

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