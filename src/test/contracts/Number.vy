number: uint256

# Methods
@external
def setNumber(_number:uint256):
    self.number = _number     # Store number in storage

@external
def getNumber() -> uint256:
    return self.number
