# Site Reliability Engineers & Operations

## Current soluton: Parameter store
For now we are utilizing AWS systems manager - parameter store for our secrets.
It is a free fully managed solution. No charge and no patching etc to do from our side.

## Things to consider
As this service provides minimun effort from our side and comes free of charge there is bound to be downsides.
The downside is that AWS put some hard limits to the service.

|Maximum size for parameter value|Max history for a parameter|Maximum number of parameters per account|
|---|---|---|
|4096 characters|100 past values|10.000|

The community also suggest that there is a limit to how often and how many secrets that can be read from parameter store.
These throttles should be investigated or at least be kept in mind in case we run into problems which could be caused by this.

{== **TODO:** From Adam and Eve I suppose... ==}

## Resources

* https://hackernoon.com/a-few-tips-for-storing-secrets-using-aws-parameter-store-f03557c5cf1b
* https://github.com/segmentio/chamber
* https://github.com/energyhub/secretly
