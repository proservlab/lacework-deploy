package main

import (
	"fmt"
	"io/ioutil"
	"net/http"
	"time"
)

func main() {

	for true {
		now := time.Now()
		tz, _ := time.LoadLocation("Europe/Paris")
		parisTime := now.In(tz)
		fmt.Printf("Local time: %s\nParis time: %s\n", now, parisTime)
		_, err := http.Get("https://golang.org/")
		if err == nil {
			fmt.Println("GoLang website is UP")
		} else {
			fmt.Printf("GoLang website is DOWN\nErr: %s\n", err.Error())
		}

		// list directory
		fmt.Println("listing directories...")
		files, err := ioutil.ReadDir("/")
		if err != nil {
			fmt.Println(err)
		}

		for _, f := range files {
			fmt.Println(f.Name())
		}

		// list directory
		fmt.Println("listing directories...")
		files2, err2 := ioutil.ReadDir("/var/lib")
		if err2 != nil {
			fmt.Println(err)
		}

		for _, f := range files2 {
			fmt.Println(f.Name())
		}

		time.Sleep(time.Second * 10)
	}
}
