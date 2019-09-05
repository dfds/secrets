# Parameter Store

The __[AWS Systems Manager Parameter Store](https://console.aws.amazon.com/systems-manager/parameters)__ is a secure, scalable, and managed configuration store that allows storage of data in hierarchies and track versions. It integrates into other AWS offerings (include AWS Lambda), and off

## Possible Limitations

As this service provides minimun effort from our side and comes free of charge there is bound to be downsides.
The downside is that AWS put some hard limits to the service.

|Maximum size for parameter value|Max history for a parameter|Maximum number of parameters per account|
|---|---|---|
|4096 characters|100 past values|10.000|

The community also suggest that there is a limit to how often and how many secrets that can be read from parameter store.
These throttles should be investigated or at least be kept in mind in case we run into problems which could be caused by this.

## Resources

* https://hackernoon.com/a-few-tips-for-storing-secrets-using-aws-parameter-store-f03557c5cf1b
* https://github.com/segmentio/chamber
* https://github.com/energyhub/secretly
