# Concierge | Backend #

### Deployment ###

Go to the root of the repository and run the following command, while specifying the correct environment:

```
#!bash

# if you want to deploy the entire codebase

./deploy.sh

# if you want to deploy just one API endpoint

./deploy.sh -c ./code/{PATH-TO-CODE}
# example:
# ./deploy.sh -c ./code/nlu/post
```

### Development ###

Go to the corresponding endpoint folder in the "code" folder. For instance, if you want to edit the API endpoint POST /nlu, you need to go to the folder ./code/nlu/post. The index.js file is the entry point to the API.
