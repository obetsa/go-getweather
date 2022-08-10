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

## Doker
docker run -d --rm -p 8080:8080 docker-getwea
