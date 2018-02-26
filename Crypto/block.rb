require 'colorize'
require 'digest'
require_relative 'pki'

class Block
  NUM_ZEROES = 4 # Difficulty

  # Set the Block properties
  attr_reader :own_hash, :prev_block_hash, :txn

  # Uses key pair to generate the first Block.
  def self.create_genesis_block(pub_key, priv_key)
    genesis_txn = Transaction.new(nil, pub_key, 500_000, priv_key)
    Block.new(nil, genesis_txn)
  end
  
  # Initialize Block. If it's genesis block we don't have previous hash
  def initialize(prev_block, txn)
    raise TypeError unless txn.is_a?(Transaction)
    @txn = txn
    @prev_block_hash = prev_block.own_hash if prev_block
    mine_block!
  end

  # Computes the hash of the Block and assigns it.
  def mine_block!
    @nonce = calc_nonce
    @own_hash = hash(full_block(@nonce))
  end

  # Assert that the Transaction in well signed.
  def valid?
    is_valid_nonce?(@nonce) && @txn.is_valid_signature?
  end

  # Pretty printer.
  def to_s
    [
      "Previous hash: ".rjust(15) + @prev_block_hash.to_s.yellow,
      "Message: ".rjust(15) + @txn.to_s.green,
      "Nonce: ".rjust(15) + @nonce.light_blue,
      "Own hash: ".rjust(15) + @own_hash.yellow,
      "↓".rjust(40),
    ].join("\n")
  end

  private

  # Gives back hash256 bit.
  def hash(contents)
    Digest::SHA256.hexdigest(contents)
  end

  # Exaustevely hashes the nonce until it matches the number of
  # zeroes required by the block to be mined.
  def calc_nonce
    nonce = "HELP I'M TRAPPED IN A NONCE FACTORY"
    count = 0
    until is_valid_nonce?(nonce)
      print "." if count % 100_000 == 0
      nonce = nonce.next
      count += 1
    end
    nonce
  end

  # Asserts that the given nonce hashed with the txn and the
  # previous hash block starts with the required number of
  # zeroes.
  def is_valid_nonce?(nonce)
    hash(full_block(nonce)).start_with?("0" * NUM_ZEROES)
  end

  # Returns the string composed by txn, prev_block_hash, nonce
  # removing eventual nils.
  def full_block(nonce)
    [@txn.to_s, @prev_block_hash, nonce].compact.join
  end
end