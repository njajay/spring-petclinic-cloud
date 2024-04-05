echo "Creating Required Services..."
{
  cf cups -p '{"uri": "https://wavefront.surf", "api-token": "2e41f7cf-1111-2222-3333-7397a56113ca", "application-name": "spring-petclinic-cloudfoundry", "fremium": "true"}' wavefront
  cf create-service -c '{ "git": { "uri": "https://github.com/njajay/spring-petclinic-cloud-config.git", "periodic": true, "label": "master"  }, "count": 3 }' p.config-server standard config

  cf create-service p.service-registry standard registry & 
  cf create-service p.mysql db-small customers-db &
  cf create-service p.mysql db-small vets-db &
  cf create-service p.mysql db-small visits-db &
  sleep 5
} &> /dev/null
until [ `cf service config | grep -c "succeeded"` -ge 1  ] && [ `cf service registry | grep -c "succeeded"` -ge 1  ] && [ `cf service customers-db | grep -c "succeeded"` -ge 1  ] && [ `cf service vets-db | grep -c "succeeded"` -ge 1  ] && [ `cf service visits-db | grep -c "succeeded"` -ge 1  ]
do
  echo "."
done

mvn clean package -Pcloud
cf push --no-start

cf add-network-policy api-gateway vets-service --protocol tcp --port 8080
cf add-network-policy api-gateway  customers-service --protocol tcp --port 8080
cf add-network-policy api-gateway  visits-service --protocol tcp --port 8080


cf start vets-service & cf start visits-service & cf start customers-service & cf start api-gateway &
