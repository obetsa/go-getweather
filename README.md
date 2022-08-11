## Getwea  -  simple weather application for getting your current forecast

- Golang / Gin
- Java Script / Axios
- Bootstrap 5
- API by www.weatherapi.com

**REST API:**
|Method|Path|Response|
|--|--|--|
|GET|/weather/search?cityName={City}|Location list|
|GET|/weather/current?cityName={City}|Current forecast|

## Docker run
sudo docker run -d --restart always -p 8080:8080 obetsa/go-getweather:latest

## Terraform
