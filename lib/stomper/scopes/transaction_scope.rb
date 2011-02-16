# -*- encoding: utf-8 -*-

# A "connection scope" that provides a convenient interface for handling
# transactions. In addition to the behaviors of {HeaderScope}, for frames
# that the Stomp protocol allows to be enclosed within a transaction, this
# scope automatically attaches a +transaction+ header.
class Stomper::Scopes::TransactionScope < ::Stomper::Scopes::HeaderScope
  # A list of frames that support being part of a transaction.
  # @return [Array<String>]
  FRAME_COMMANDS = %w(SEND BEGIN COMMIT ABORT ACK NACK)
  # The value assigned to the +transaction+ header.
  # @return [String]
  attr_reader :transaction
  
  def initialize(parent, headers)
    super
    @headers[:transaction] ||= ::Stomper::Support.next_serial
    @transaction = self.headers[:transaction]
    @transaction_state = :pending
  end
  
  # Overrides the standard {Stomper::Extensions::Commmon#begin} behavior
  # to start the transaction encapsulated by this {TransactionScope transaction}.
  def begin_with_transaction(headers={})
    if transaction_pending?
      @transaction_state = :starting
    else
      raise ::Stomper::Errors::TransactionStartedError unless transaction_pending?
    end
    begin_without_transaction(@transaction, headers).tap do |f|
      @transaction_state = :started
    end
  end
  alias :begin_without_transaction :begin
  alias :begin :begin_with_transaction
  
  # Overrides the standard {Stomper::Extensions::Commmon#abort} behavior
  # to abort the transaction encapsulated by this {TransactionScope transaction}.
  def abort_with_transaction(headers={})
    abort_without_transaction(@transaction, headers).tap do |f|
      @transaction_state = :aborted
    end
  end
  alias :abort_without_transaction :abort
  alias :abort :abort_with_transaction
  
  # Overrides the standard {Stomper::Extensions::Commmon#commit} behavior
  # to commit the transaction encapsulated by this {TransactionScope transaction}.
  def commit_with_transaction(headers={})
    commit_without_transaction(@transaction, headers).tap do |f|
      @transaction_state = :committed
    end
  end
  alias :commit_without_transaction :commit
  alias :commit :commit_with_transaction
  
  # Transmits a frame, but only applies the +transaction+ header if the
  # frame command is amongst those commands that can be included in a
  # transaction.
  # @param [Stomper::Frame] frame
  def transmit(frame)
    self.begin if transaction_pending?
    if FRAME_COMMANDS.include? frame.command
      if frame.command != 'BEGIN' && transaction_finalized?
        raise ::Stomper::Errors::TransactionFinalizedError
      end
      super(frame)
    else
      @connection.transmit frame
    end
  end
  
  # Applies this transaction to a block. Before any transactionable frame
  # is transmitted within the block, a BEGIN frame will be generated. If
  # the block completes without raising an error, a COMMIT frame will be
  # transmitted to complete the transaction, otherwise an ABORT frame will
  # be transmitted signalling that the transaction should be rolled-back by
  # the broker.
  def apply_to(callback)
    begin
      super
      self.commit if transaction_started?
    rescue Exception => err
      self.abort if transaction_started?
      raise err
    end
  end
  
  # Returns true if a BEGIN frame has not yet been transmitted for this
  # transaction, false otherwise.
  # @return [true, false]
  def transaction_pending?; @transaction_state == :pending; end
  # Returns true if a BEGIN frame has been transmitted for this
  # transaction but neither COMMIT nor ABORT have been sent, false otherwise.
  # @return [true, false]
  def transaction_started?; @transaction_state == :started; end
  # Returns true if a COMMIT frame has been transmitted for this
  # transaction, false otherwise.
  # @return [true, false]
  def transaction_committed?; @transaction_state == :committed; end
  # Returns true if an ABORT frame has been transmitted for this
  # transaction, false otherwise.
  # @return [true, false]
  def transaction_aborted?; @transaction_state == :aborted; end
  # Returns true if a COMMIT or ABORT frame has been transmitted for this
  # transaction, false otherwise.
  # @return [true, false]
  def transaction_finalized?; transaction_aborted? || transaction_committed?; end
end
