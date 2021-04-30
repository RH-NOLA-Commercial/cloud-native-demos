# Pasos para instalar Demos

1. Se debe aprovisionar el workshop **"CCN Roadshow for Dev Track (T - OCP 4.5)"**  (Es posible con otro cluster de OpenShift pero de momento este es el que se ha utilizado para prueba)
2. Ingresar via CLI al cluster (Se debe tener el cliente OC en la máquina)
```
oc login <cluster URL> --username=<usuario> --password=<password>
```
3. Crear proyecto / namespace donde se desplegara el demo
```
oc new-project demo-cn
```
4. Ejecutar script **"deploy_cn_basic_demo.sh"** con los siguientes parametros

| Parametro | Ejemplo |
| ----------- | ----------- |
| OCP Project | demo-cn |
| Carpeta Base | /home/user/Documents/cloud-native-demos |

```
sh deploy_cn_basic_demo.sh demo-cn /home/user/Documents/cloud-native-demos
```