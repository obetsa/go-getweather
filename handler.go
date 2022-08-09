package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

func main0(c *gin.Context) {
	c.HTML(http.StatusOK, "start.html", gin.H{
		"title": "Start page",
		"Text":  "Hello from my new fresh server",
	})

}

func hindex(c *gin.Context) {
	c.Redirect(http.StatusMovedPermanently, "/main")
}

func hmain(c *gin.Context) {
	c.HTML(http.StatusOK, "main.html", gin.H{
		"title":       "Weather info",
		"placeholder": "Enter the name of the city",
		"label":       "Select the nearest location:",
	})
}

func hweather(c *gin.Context) {

	var (
		requestType   = c.Param("reqType")
		cityName      = c.Query("cityName")
		apiUrl        = fmt.Sprintf("http://api.weatherapi.com/v1/%v.json?key=6ca11730e8a04feb9bf83407222606&lang=en&q=%v&aqi=no", requestType, cityName)
		timeOutClinet = http.Client{
			Timeout: time.Second * 2,
		}
		HTTPReq, _     = http.NewRequest(http.MethodGet, apiUrl, nil)
		HTTPRes, _     = timeOutClinet.Do(HTTPReq)
		HTTPResBody, _ = ioutil.ReadAll(HTTPRes.Body)
	)

	if requestType == "search" {

		searchStruct := weatherSearch{}

		jsonErr := json.Unmarshal(HTTPResBody, &searchStruct)
		if jsonErr != nil {
			log.Fatal(jsonErr)
		}

		c.JSON(200, searchStruct)

	} else if requestType == "current" {

		currentStruct := weatherCurrent{}

		jsonErr := json.Unmarshal(HTTPResBody, &currentStruct)
		if jsonErr != nil {
			log.Fatal(jsonErr)
		}

		c.JSON(200, currentStruct)

	} else {
		c.JSON(404, gin.H{"code": "404", "message": "Undefined query"})
	}

}
