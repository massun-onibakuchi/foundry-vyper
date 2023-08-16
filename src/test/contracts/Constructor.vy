number: uint256

event ArgumentsUpdated:
    topicOne: indexed(address)
    topicTwo: indexed(uint256)

getArgOne: public(address)
getArgTwo: public(uint256)

# Methods
@external
def __init__(one:address, two:uint256):
    self.getArgOne = one
    self.getArgTwo = two
    log ArgumentsUpdated(one, two)
