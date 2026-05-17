// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract YulMath {
    function sqrt(uint256 x) public pure returns (uint256 result) {
        assembly {
            if gt(x, 3) {
                result := x
                let tmp := add(div(x, 2), 1)
                for {} lt(tmp, result) {} {
                    result := tmp
                    tmp := div(add(div(x, tmp), tmp), 2)
                }
            }
            if and(gt(x, 0), lt(x, 4)) {
                result := 1
            }
        }
    }

    function min(uint256 a, uint256 b) public pure returns (uint256 result) {
        assembly {
            result := xor(a, mul(xor(a, b), lt(b, a)))
        }
    }

    function max(uint256 a, uint256 b) public pure returns (uint256 result) {
        assembly {
            result := xor(a, mul(xor(a, b), gt(b, a)))
        }
    }

    function mulDiv(uint256 x, uint256 y, uint256 denominator) public pure returns (uint256 result) {
        assembly {
            let prod := mul(x, y)
            result := div(prod, denominator)
        }
    }
}
