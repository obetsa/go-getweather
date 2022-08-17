## Infrastructure with AWS Cloud 
![alt text](https://github.com/obetsa/go-getweather/blob/main/go-getweather.png?raw=true)
Folder structure:
./
├─ config
│  └─ (create structure files)
└ application

Steps:
1. Create application
2. Add to github
3. Create docker image and add to dockerhub
4. Create docker-compose.yml
5. Create terraform organization
6. Create new user AWS for project and key (IAM Role)
7. Create bash script for service doker in ec2
8. Variable set(terraform, git..etc)
9. Create terraform infrastructure (first init)
10. Publish release(git)
11. Add auto-scaling group and load balancer to AWS
12. Create cluster group in privat subnet 
13. Crete S3 bucket
14. Use Puppet in cluster group
15. Add HAProxy 80:8080 for ec2 machine(http)
16. Attach Gitlub to project
17. Attach Jenkins to project
Will finish later:
18. Add aws cloud front(for metrics)
19. Open 443 port(https) and create certificate
20. AWS lambda function to get logs from ec2 and push it in to S3 bucket

To crete project:
 - git clone https://github.com/obetsa/go-getweather
 - go to folder ./go-getweather/config
 - use terraform

### Terraform
terraform init
terraform apply

### Kubernetes
kubectl apply -f .

### Docker
Dockerhub image:
sudo docker run -d --restart always -p 8080:8080 obetsa/go-getweather:latest

## Application (CI/CD)
Uses Gitlab and Jenkins as a part of project
 - https://gitlab.com/obetsa/go-getweather

## Application (Coding)
Application :
go-getweather  -  simple weather application for getting your current forecast
Use:
- Golang / Gin
- Java Script / Axios
- Bootstrap 5
- API by www.weatherapi.com