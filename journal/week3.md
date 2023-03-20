# Week 3 — Decentralized Authentication

## Provision Cognito User Group

Create AWS Cognito User Pool from AWS Console or using the following CloudFormation template: 
https://raw.githubusercontent.com/bayupw/aws-bootcamp-cruddur-2023/main/cruddur-simple-cognito-cfn.yml

Using the AWS Console we'll create a Cognito User Group

## Configure AWS Amplify

Import amplify add add cognito details into the `app.js` under `frontend-react-js/src/`

```js
import { Amplify } from 'aws-amplify';

Amplify.configure({
  "AWS_PROJECT_REGION": process.env.REACT_APP_AWS_PROJECT_REGION,
  "aws_cognito_region": process.env.REACT_APP_AWS_COGNITO_REGION,
  "aws_user_pools_id": process.env.REACT_APP_AWS_USER_POOLS_ID,
  "aws_user_pools_web_client_id": process.env.REACT_APP_CLIENT_ID,
  "oauth": {},
  Auth: {
    region: process.env.REACT_APP_AWS_PROJECT_REGION,
    userPoolId: process.env.REACT_APP_AWS_USER_POOLS_ID,
    userPoolWebClientId: process.env.REACT_APP_CLIENT_ID,
  }
});
```

## Update Home Feed Page

Add the following code into the `HomeFeedPage.js` under `frontend-react-js/src/pages`

```js
import { Auth } from 'aws-amplify';


// replace line 40-49 `const checkAuth` with the following code to check whether user is authenticated or not
const checkAuth = async () => {
  Auth.currentAuthenticatedUser({
    // Optional, By default is false. 
    // If set to true, this call will send a 
    // request to Cognito to get the latest user data
    bypassCache: false 
  })
  .then((user) => {
    console.log('user',user);
    return Auth.currentAuthenticatedUser()
  }).then((cognito_user) => {
      setUser({
        display_name: cognito_user.attributes.name,
        handle: cognito_user.attributes.preferred_username
      })
  })
  .catch((err) => console.log(err));
};
```

Add the following code into the `ProfileInfo.js` under `frontend-react-js/src/components`

```js
// comment out or delete `import Cookies from 'js-cookie'` 
// import Cookies from 'js-cookie'
import { Auth } from 'aws-amplify';

// replace line 14-26 `const signOut` with the following code
const signOut = async () => {
  try {
      await Auth.signOut({ global: true });
      window.location.href = "/"
  } catch (error) {
      console.log('error signing out: ', error);
  }
}
```

## Update Sign In Page

Add the following code into the `SigninPage.js` under `frontend-react-js/src/pages`

```js
// comment out or delete `import Cookies from 'js-cookie'` 
// import Cookies from 'js-cookie'
import { Auth } from 'aws-amplify';

// replace line 15-26 `const onsubmit` with the following code
const onsubmit = async (event) => {
  setErrors('')
  event.preventDefault();
  Auth.signIn(email, password)
  .then(user => {
    console.log('user',user)
    localStorage.setItem("access_token", user.signInUserSession.accessToken.jwtToken)
    window.location.href = "/"
  })
  .catch(error => { 
    if (error.code == 'UserNotConfirmedException') {
      window.location.href = "/confirm"
    }
    setErrors(error.message)
  });
  return false
}
```

Add the following Env Var to `frontend-react-js:` under section `environment:` in `docker-compose.yml` file

```yml
      REACT_APP_AWS_PROJECT_REGION: "${AWS_DEFAULT_REGION}"
      REACT_APP_AWS_COGNITO_REGION: "${AWS_DEFAULT_REGION}"
      REACT_APP_AWS_USER_POOLS_ID: "${REACT_APP_AWS_USER_POOLS_ID}"
      REACT_APP_CLIENT_ID: "${REACT_APP_CLIENT_ID}"
```

## Update Signup Page

Add the following code into the `SignupPage.js` under `frontend-react-js/src/pages`

```js
// comment out or delete `import Cookies from 'js-cookie'` 
// import Cookies from 'js-cookie'
import { Auth } from 'aws-amplify';

// replace line 17-30 `const onsubmit` with the following code
const onsubmit = async (event) => {
  event.preventDefault();
  setErrors('')
  try {
      const { user } = await Auth.signUp({
        username: email,
        password: password,
        attributes: {
            name: name,
            email: email,
            preferred_username: username,
        },
        autoSignIn: { // optional - enables auto sign in after user is confirmed
            enabled: true,
        }
      });
      console.log(user);
      window.location.href = `/confirm?email=${email}`
  } catch (error) {
      console.log(error);
      setErrors(error.message)
  }
  return false
}

let errors;
if (cognitoErrors){
  errors = <div className='errors'>{cognitoErrors}</div>;
}

//before submit component
{errors}
```

## Update Confirmation Page

Add the following code into the `SignupPage.js` under `frontend-react-js/src/pages`

```js
// comment out or delete `import Cookies from 'js-cookie'` 
// import Cookies from 'js-cookie'
import { Auth } from 'aws-amplify';

// replace `const resend_code` with the following code
const resend_code = async (event) => {
  setErrors('')
  try {
    await Auth.resendSignUp(email);
    console.log('code resent successfully');
    setCodeSent(true)
  } catch (err) {
    // does not return a code
    // does cognito always return english
    // for this to be an okay match?
    console.log(err)
    if (err.message == 'Username cannot be empty'){
      setErrors("You need to provide an email in order to send Resend Activiation Code")   
    } else if (err.message == "Username/client id combination not found."){
      setErrors("Email is invalid or cannot be found.")   
    }
  }
}

// replace `const onsubmit` with the following code
  const onsubmit = async (event) => {
    event.preventDefault();
    setErrors('')
    try {
      await Auth.confirmSignUp(email, code);
      window.location.href = "/"
    } catch (error) {
      setErrors(error.message)
    }
    return false
  }
```

## Update Recovery Page

Add the following code into the `RecoverPage.js` under `frontend-react-js/src/pages`

```js
// comment out or delete `import Cookies from 'js-cookie'` 
// import Cookies from 'js-cookie'
import { Auth } from 'aws-amplify';

const onsubmit_send_code = async (event) => {
  event.preventDefault();
  setErrors('')
  Auth.forgotPassword(username)
  .then((data) => setFormState('confirm_code') )
  .catch((err) => setErrors(err.message) );
  return false
}

const onsubmit_confirm_code = async (event) => {
  event.preventDefault();
  setErrors('')
  if (password == passwordAgain){
    Auth.forgotPasswordSubmit(username, code, password)
    .then((data) => setFormState('success'))
    .catch((err) => setErrors(err.message) );
  } else {
    setErrors('Passwords do not match')
  }
  return false
}

## Test the updated code 

Cognito User Pool ID and Client ID can also be retrieved from the CloudFormation stack output
![Cognito CloudFormation Stack Output](../_docs/assets/cruddur-cognito-stack-screenshot.png)

```sh
cd frontend-react-js
npm install aws-amplify --save
npm install

export AWS_ACCESS_KEY_ID="keyid"
export AWS_SECRET_ACCESS_KEY="secretkey"
export AWS_DEFAULT_REGION="ap-southeast-2"
export REACT_APP_AWS_USER_POOLS_ID="UserPoolClientID"
export REACT_APP_CLIENT_ID="AWS Cognito Client ID"

gp env AWS_ACCESS_KEY_ID="keyid"
gp env AWS_SECRET_ACCESS_KEY="secretkey"
gp env AWS_DEFAULT_REGION="ap-southeast-2"
gp env REACT_APP_AWS_USER_POOLS_ID="UserPoolClientID"
gp env REACT_APP_CLIENT_ID="UserPoolID"

cd ..
docker compose -f "docker-compose.yml" up -d --build
```