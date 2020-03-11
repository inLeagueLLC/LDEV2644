[![Build Status](https://travis-ci.org/coldbox-modules/cbvalidation.svg?branch=development)](https://travis-ci.org/coldbox-modules/cbvalidation)

# WELCOME TO THE COLDBOX VALIDATION MODULE

This module is a server side rules validation engine that can provide you with a unified approach to object, struct and form validation.  You can construct validation constraint rules and then tell the engine to validate them accordingly.

## LICENSE

Apache License, Version 2.0.

## IMPORTANT LINKS

- https://github.com/coldbox-modules/cbvalidation
- https://coldbox-validation.ortusbooks.com
- https://forgebox.io/view/cbvalidation

## SYSTEM REQUIREMENTS

- Lucee 5.x+
- Adobe ColdFusion 2016+

## Installation

Leverage CommandBox to install:

`box install cbvalidation`

The module will register several objects into WireBox using the `@cbvalidation` namespace.  The validation manager is registered as `ValidationManager@cbvalidation`.  It will also register several helper methods that can be used throughout the ColdBox application: `validate(), validateOrFail(), getValidationManager()`

## Mixins

The module will also register several methods in your handlers/interceptors/layouts/views

```js
/**
 * Validate an object or structure according to the constraints rules.
 *
 * @target An object or structure to validate
 * @fields The fields to validate on the target. By default, it validates on all fields
 * @constraints A structure of constraint rules or the name of the shared constraint rules to use for validation
 * @locale The i18n locale to use for validation messages
 * @excludeFields The fields to exclude from the validation
 * @includeFields The fields to include in the validation
 *
 * @return cbvalidation.model.result.IValidationResult
 */
function validate()

/**
 * Validate an object or structure according to the constraints rules and throw an exception if the validation fails.
 * The validation errors will be contained in the `extendedInfo` of the exception in JSON format
 *
 * @target An object or structure to validate
 * @fields The fields to validate on the target. By default, it validates on all fields
 * @constraints A structure of constraint rules or the name of the shared constraint rules to use for validation
 * @locale The i18n locale to use for validation messages
 * @excludeFields The fields to exclude from the validation
 * @includeFields The fields to include in the validation
 *
 * @return The validated object or the structure fields that where validated
 * @throws ValidationException
 */
function validateOrFail()

/**
 * Retrieve the application's configured Validation Manager
 */
function getValidationManager()
```

## Settings

Here are the module settings you can place in your `ColdBox.cfc` by using the `validation` settings structure:

```js
validation = {
    // The third-party validation manager to use, by default it uses CBValidation.
    manager = "class path",
    
    // You can store global constraint rules here with unique names
    sharedConstraints = {
        name = {
            field = { constraints here }
        }
    }

}
```

You can read more about ColdBox Validation here: - https://coldbox-validation.ortusbooks.com/

## Constraints

Please check out the docs for the latest on constraints: https://coldbox-validation.ortusbooks.com/overview/valid-constraints.  Constraints rely on rules you apply to incoming fields of data. They can be created on objects or stored wherever you like, as long as you pass them to the validation methods.

Each property can have one or more constraints attached to it.  In an object you can create a `this.constraints` and declare them by the fields you like:

```js
this.constraints = {

	propertyName = {
		// The field under validation must be yes, on, 1, or true. This is useful for validating "Terms of Service" acceptance.
		accepted : any value,

		// The field must be alpahbetical ONLY
		alpha : any value,

		// discrete math modifiers
		discrete : (gt,gte,lt,lte,eq,neq):value

		// value in list
		inList : list,

		// max value
		max : value,

		// Validation method to use in the target object must return boolean accept the incoming value and target object 
		method : methodName,

		// min value
		min : value,

		// range is a range of values the property value should exist in
		range : eg: 1..10 or 5..-5,
		
		// regex validation
		regex : valid no case regex

		// required field or not, includes null values
		required : boolean [false],

		// The field under validation must be present and not empty if the `anotherfield` field is equal to the passed `value`.
		requiredIf : {
			anotherfield:value, anotherfield:value
		}
		
		// The field under validation must be present and not empty unless the `anotherfield` field is equal to the passed 
		requiredUnless : {
			anotherfield:value, anotherfield:value
		}
		
		// same as but with no case
		sameAsNoCase : propertyName

		// same as another property
		sameAs : propertyName

		// size or length of the value which can be a (struct,string,array,query)
		size  : numeric or range, eg: 10 or 6..8

		// specific type constraint, one in the list.
		type  : (ssn,email,url,alpha,boolean,date,usdate,eurodate,numeric,GUID,UUID,integer,string,telephone,zipcode,ipaddress,creditcard,binary,component,query,struct,json,xml),

		// UDF to use for validation, must return boolean accept the incoming value and target object, validate(value,target):boolean
		udf = variables.UDF or this.UDF or a closure.

		// Check if a column is unique in the database
		unique = {
			table : The table name,
			column : The column to check, defaults to the property field in check
		}
		
		// Custom validator, must implement coldbox.system.validation.validators.IValidator
		validator : path or wirebox id, example: 'mypath.MyValidator' or 'id:MyValidator'
	}

}
```

```
********************************************************************************
Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
www.coldbox.org | www.luismajano.com | www.ortussolutions.com
********************************************************************************
```

### HONOR GOES TO GOD ABOVE ALL

Because of His grace, this project exists. If you don't like this, then don't read it, its not for you.

>"Therefore being justified by faith, we have peace with God through our Lord Jesus Christ:
By whom also we have access by faith into this grace wherein we stand, and rejoice in hope of the glory of God.
And not only so, but we glory in tribulations also: knowing that tribulation worketh patience;
And patience, experience; and experience, hope:
And hope maketh not ashamed; because the love of God is shed abroad in our hearts by the 
Holy Ghost which is given unto us. ." Romans 5:5

### THE DAILY BREAD

 > "I am the way, and the truth, and the life; no one comes to the Father, but by me (JESUS)" Jn 14:1-12