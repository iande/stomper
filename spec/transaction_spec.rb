require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

module Stomper
  describe Transaction do
    before(:each) do
      @mock_client = mock("client")
    end

    describe "initialization with blocks" do
      before(:each) do
        @mock_client.should_receive(:begin).once.with(an_instance_of(String)).and_return(nil)
        @mock_client.should_receive(:send).once.with("/queue/test/1","a message", an_instance_of(Hash)).and_return(nil)
        @mock_client.should_receive(:commit).once.with(an_instance_of(String)).and_return(nil)
      end


      it "should provide a DSL when a block with no arguments is given" do
        lambda do
          Transaction.new(@mock_client) do
            send("/queue/test/1", "a message")
          end
        end.should_not raise_error
      end

      it "should yield itself when a block with arguments is given" do
        lambda do
          Transaction.new(@mock_client) do |t|
            t.send("/queue/test/1", "a message")
          end
        end.should_not raise_error
      end
    end

    describe "explicitly named" do
      before(:each) do
        @transaction_name = "tx-test"
        @mock_client.should_receive(:begin).once.with(@transaction_name).and_return(nil)
        @mock_client.should_receive(:send).once.with("/queue/test/1","test message", hash_including(:transaction => @transaction_name)).and_return(nil)
        @mock_client.should_receive(:commit).once.with(@transaction_name).and_return(nil)
      end

      it "should use the given transaction ID as the transaction header in stomp messages" do
        Transaction.new(@mock_client, @transaction_name) do |t|
          t.send("/queue/test/1", "test message")
        end
      end
    end

    describe "aborting failed transactions" do
      before(:each) do
        @transaction_name = "tx-test-2"
        @mock_client.should_receive(:begin).once.with(@transaction_name).and_return(nil)
        @mock_client.should_receive(:send).once.with("/queue/test/1","test message", hash_including(:transaction => @transaction_name)).and_return(nil)
      end

      it "should abort when an exception is raised" do
        @mock_client.should_receive(:abort).once.with(@transaction_name).and_return(nil)
        @mock_client.should_not_receive(:commit)
        lambda do
          Transaction.new(@mock_client, @transaction_name) do |t|
            t.send("/queue/test/1", "test message")
            raise "Never to be completed!"
          end
        end.should raise_error(TransactionAborted)
      end

      it "should abort and raise an error when explicitly aborted" do
        @mock_client.should_receive(:abort).once.with(@transaction_name).and_return(nil)
        @mock_client.should_not_receive(:commit)
        lambda do
          Transaction.new(@mock_client, @transaction_name) do |t|
            t.send("/queue/test/1", "test message")
            t.abort
            # This should never be reached.
            t.commit
          end
        end.should raise_error(TransactionAborted)
      end

      it "should not raise an exception when explicitly aborted after a commit" do
        @mock_client.should_not_receive(:abort)
        @mock_client.should_receive(:commit).once.with(@transaction_name).and_return(nil)
        lambda do
          Transaction.new(@mock_client, @transaction_name) do |t|
            t.send("/queue/test/1", "test message")
            t.commit
            t.abort
          end
        end.should_not raise_error(TransactionAborted)
      end
    end

    describe "nested transactions" do
      before(:each) do
        @transaction_name = "tx-test-3"
        @inner_transaction_name = "#{@transaction_name}-inner"
        @inner_inner_transaction_name = "#{@transaction_name}-inner-inner"
        @mock_client.should_receive(:begin).with(@transaction_name).once.and_return(nil)
        @mock_client.should_receive(:begin).with(@inner_transaction_name).once.and_return(nil)
        @mock_client.should_receive(:send).with("/queue/test/1","test message", hash_including(:transaction => @transaction_name)).once.and_return(nil)
        @mock_client.should_receive(:send).with("/queue/test/2","inner message", hash_including(:transaction => @inner_transaction_name)).once.and_return(nil)
      end
      it "no transaction should succeed when an inner one fails" do
        @mock_client.should_receive(:abort).once.with(@transaction_name).and_return(nil)
        @mock_client.should_receive(:abort).once.with(@inner_transaction_name).and_return(nil)
        @mock_client.should_not_receive(:commit)
        lambda do
          Transaction.new(@mock_client, @transaction_name) do |t|
            t.send("/queue/test/1", "test message")
            t.transaction(@inner_transaction_name) do |nt|
              nt.send("/queue/test/2", "inner message")
              raise "failure"
            end
          end
        end.should raise_error(TransactionAborted)
      end
      it "no transaction should succeed when an inner one is explicitly aborted" do
        @mock_client.should_receive(:begin).with(@inner_inner_transaction_name).once.and_return(nil)
        @mock_client.should_receive(:send).with("/queue/test/3","inner-inner message", hash_including(:transaction => @inner_inner_transaction_name)).once.and_return(nil)
        @mock_client.should_receive(:abort).once.with(@transaction_name).and_return(nil)
        @mock_client.should_receive(:abort).once.with(@inner_transaction_name).and_return(nil)
        @mock_client.should_receive(:abort).once.with(@inner_inner_transaction_name).and_return(nil)
        @mock_client.should_not_receive(:commit)
        lambda do
          Transaction.new(@mock_client, @transaction_name) do |t|
            t.send("/queue/test/1", "test message")
            t.transaction(@inner_transaction_name) do |nt|
              nt.send("/queue/test/2", "inner message")
              nt.transaction(@inner_inner_transaction_name) do |nnt|
                nnt.send("/queue/test/3", "inner-inner message")
                nnt.abort
              end
            end
          end
        end.should raise_error(TransactionAborted)
      end
    end
  end
end
