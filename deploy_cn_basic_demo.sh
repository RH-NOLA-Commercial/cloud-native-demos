echo "You are going to deploy Cloud Native Basic Demo in project: $1"
echo "Your root folder is $2"

oc project $1

# Deploy Inventory
oc new-app --name=inventory-database -p DATABASE_SERVICE_NAME=inventory-database -p POSTGRESQL_USER=inventory -p POSTGRESQL_PASSWORD=mysecretpassword -p POSTGRESQL_DATABASE=inventory --template=postgresql-ephemeral -n $1
mvn clean compile package -DskipTests -f $2/cloud-native-basic-demo/inventory-service
oc rollout status -w dc/inventory -n $1
oc label dc/inventory app.kubernetes.io/part-of=inventory --overwrite -n $1
oc label dc/inventory-database app.kubernetes.io/part-of=inventory app.openshift.io/runtime=postgresql --overwrite -n $1
oc annotate dc/inventory app.openshift.io/connects-to=inventory-database --overwrite -n $1
oc annotate dc/inventory app.openshift.io/vcs-ref=ocp-4.7 --overwrite -n $1


#Deploy Catalog
mvn clean package spring-boot:repackage -DskipTests -f $2/cloud-native-basic-demo/catalog-service
oc new-app --name=catalog-database -p DATABASE_SERVICE_NAME=catalog-database -p POSTGRESQL_USER=catalog -p POSTGRESQL_PASSWORD=mysecretpassword -p POSTGRESQL_DATABASE=catalog --template=postgresql-ephemeral -n $1
oc new-build registry.access.redhat.com/ubi8/openjdk-11 --binary --name=catalog -l app=catalog -n $1
oc start-build catalog --from-file=$2/cloud-native-basic-demo/catalog-service/target/catalog-1.0.0-SNAPSHOT.jar --follow -n $1
oc new-app catalog  --as-deployment-config -e JAVA_OPTS_APPEND='-Dspring.profiles.active=openshift' && oc expose service catalog -n $1
oc label dc/catalog app.kubernetes.io/part-of=catalog app.openshift.io/runtime=rh-spring-boot --overwrite -n $1
oc label dc/catalog-database app.kubernetes.io/part-of=catalog app.openshift.io/runtime=postgresql --overwrite -n $1
oc annotate dc/catalog app.openshift.io/connects-to=inventory,catalog-database --overwrite -n $1
oc annotate dc/catalog app.openshift.io/vcs-uri=https://github.com/RedHat-Middleware-Workshops/cloud-native-basic-demo.git --overwrite -n $1
oc annotate dc/catalog app.openshift.io/vcs-ref=ocp-4.7 --overwrite -n $1

# Deploy Cart Service
oc new-app --as-deployment-config infinispan/server:12.0.0.Final-1 --name=datagrid-service -e USER=user -e PASS=pass -n $1
mvn clean package -DskipTests -f $2/cloud-native-basic-demo/cart-service
oc rollout status -w dc/cart -n $1
oc label dc/cart app.kubernetes.io/part-of=cart app.openshift.io/runtime=quarkus --overwrite -n $1
oc label dc/datagrid-service app.kubernetes.io/part-of=cart app.openshift.io/runtime=datagrid --overwrite -n $1
oc annotate dc/cart app.openshift.io/connects-to=catalog,datagrid-service --overwrite -n $1
oc annotate dc/cart app.openshift.io/vcs-ref=ocp-4.7 --overwrite -n $1

# Deploy Order Service
oc new-app -n $1  --as-deployment-config --docker-image mongo:4.0 --name=order-database
mvn clean package -DskipTests -f $2/cloud-native-basic-demo/order-service
oc rollout status -w dc/order -n $1
oc label dc/order app.kubernetes.io/part-of=order --overwrite -n $1
oc label dc/order-database app.kubernetes.io/part-of=order app.openshift.io/runtime=mongodb --overwrite -n $1
oc annotate dc/order app.openshift.io/connects-to=order-database --overwrite -n $1
oc annotate dc/order app.openshift.io/vcs-ref=ocp-4.7 --overwrite -n $1

# Deploy WEB-UI
cd $2/cloud-native-basic-demo/coolstore-ui && npm install --save-dev nodeshift
npm run nodeshift && oc expose svc/coolstore-ui
oc label dc/coolstore-ui app.kubernetes.io/part-of=coolstore --overwrite -n $1
oc annotate dc/coolstore-ui app.openshift.io/connects-to=order-cart,catalog,inventory,order --overwrite -n $1
oc annotate dc/coolstore-ui app.openshift.io/vcs-uri=https://github.com/RedHat-Middleware-Workshops/cloud-native-basic-demo.git --overwrite -n $1
oc annotate dc/coolstore-ui app.openshift.io/vcs-ref=ocp-4.7 --overwrite -n $1