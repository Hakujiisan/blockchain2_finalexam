import { BigInt, Bytes } from "@graphprotocol/graph-ts"
import { TransferSingle } from "../generated/GameItems/GameItems"
import { Swap as SwapEvent, LiquidityAdded } from "../generated/ResourceAMM/ResourceAMM"
import { CraftCompleted } from "../generated/GameItems/GameItems"
import { Player, ItemBalance, CraftEvent, Swap, LiquidityEvent } from "../generated/schema"

function getOrCreatePlayer(address: Bytes): Player {
  let id = address.toHexString()
  let player = Player.load(id)
  if (!player) {
    player = new Player(id)
    player.address = address
    player.craftCount = BigInt.fromI32(0)
    player.swapCount = BigInt.fromI32(0)
    player.save()
  }
  return player
}

export function handleTransferSingle(event: TransferSingle): void {
  if (event.params.from.toHexString() == "0x0000000000000000000000000000000000000000") {
    return
  }
  let player = getOrCreatePlayer(event.params.to)
  let balanceId = event.params.to.toHexString() + "-" + event.params.id.toString()
  let balance = ItemBalance.load(balanceId)
  if (!balance) {
    balance = new ItemBalance(balanceId)
    balance.player = player.id
    balance.tokenId = event.params.id
    balance.amount = BigInt.fromI32(0)
  }
  balance.amount = balance.amount.plus(event.params.value)
  balance.updatedAt = event.block.timestamp
  balance.save()
}

export function handleCraftCompleted(event: CraftCompleted): void {
  let player = getOrCreatePlayer(event.params.player)
  player.craftCount = player.craftCount.plus(BigInt.fromI32(1))
  player.save()

  let craftId = event.transaction.hash.toHexString() + "-" + event.logIndex.toString()
  let craft = new CraftEvent(craftId)
  craft.player = player.id
  craft.outputId = event.params.outputId
  craft.amount = event.params.amount
  craft.timestamp = event.block.timestamp
  craft.blockNumber = event.block.number
  craft.save()
}

export function handleSwap(event: SwapEvent): void {
  let player = getOrCreatePlayer(event.params.trader)
  player.swapCount = player.swapCount.plus(BigInt.fromI32(1))
  player.save()

  let swapId = event.transaction.hash.toHexString() + "-" + event.logIndex.toString()
  let swap = new Swap(swapId)
  swap.trader = event.params.trader
  swap.tokenIn = event.params.tokenIn
  swap.amountIn = event.params.amountIn
  swap.amountOut = event.params.amountOut
  swap.timestamp = event.block.timestamp
  swap.blockNumber = event.block.number
  swap.save()
}

export function handleLiquidityAdded(event: LiquidityAdded): void {
  let id = event.transaction.hash.toHexString() + "-" + event.logIndex.toString()
  let liqEvent = new LiquidityEvent(id)
  liqEvent.provider = event.params.provider
  liqEvent.amount0 = event.params.amount0
  liqEvent.amount1 = event.params.amount1
  liqEvent.lpMinted = event.params.liquidity
  liqEvent.timestamp = event.block.timestamp
  liqEvent.save()
}