# Concierge | Backend #

### Deployment ###

Go to the root of the repository and run the following command, while specifying the correct environment:

```
#!bash

# if you want to deploy the entire codebase

./deploy.sh -e {dev, qa, prod} -p {aws profile} -r {aws region}

# if you want to deploy just one API endpoint

./deploy.sh -c ./code/{PATH-TO-CODE} -e {dev, qa, prod} -p {aws profile} -r {aws region}
# example:
# ./deploy.sh -c ./code/nlu/post -e dev -p concierge-demo -r us-east-1
```

### Development ###

Go to the corresponding endpoint folder in the "code" folder. For instance, if you want to edit the API endpoint POST /nlu, you need to go to the folder ./code/nlu/post. The index.js file is the entry point to the API.
