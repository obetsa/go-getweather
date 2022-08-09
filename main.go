package main

import (
	"log"

	"github.com/gin-gonic/gin"
)

func main() {
	app := gin.Default()
	app.Static("/files", "./static")
	app.LoadHTMLGlob("templates/**/*")
	app.GET("/start", main0)
	app.GET("/", hindex)
	app.GET("/main", hmain)
	app.GET("/weather/:reqType", hweather)
	err := app.Run(":8080")
	if err != nil {
		log.Fatalln("Error server start")
	}

}
