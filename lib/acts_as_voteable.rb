module ThumbsUp
  module ActsAsVoteable #:nodoc:

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def acts_as_voteable options={}
        has_many :votes, :as => :voteable, :dependent => :destroy

        include ThumbsUp::ActsAsVoteable::InstanceMethods
        extend  ThumbsUp::ActsAsVoteable::SingletonMethods
        if (options[:vote_counter])
          Vote.send(:include, ThumbsUp::ActsAsVoteable::VoteCounterClassMethods) unless Vote.respond_to?(:vote_counters)
          Vote.vote_counters = [self]
          vote_counter_column = (options[:vote_counter] == true) ? :vote_count : options[:vote_counter]
          define_method(:vote_counter_column) {vote_counter_column}
          define_method(:reload_vote_counter) {reload(:select => vote_counter_column.to_s)}
          attr_readonly vote_counter_column
        end
      end
    end
    
    module VoteCounterClassMethods
      def self.included(base)
        base.class_inheritable_array(:vote_counters)
        base.after_create { |record| record.update_vote_counters(1) }
        base.before_destroy { |record| record.update_vote_counters(-1) }
      end
      
      def update_vote_counters direction
        klass, vtbl = self.voteable.class, self.voteable
        klass.update_counters(vtbl.id, vtbl.vote_counter_column.to_sym => (self.vote * direction) ) if self.vote_counters.any?{|c| c == klass}
      end
    end

    module SingletonMethods

      # Calculate the vote counts for all voteables of my type.
      # This method returns all voteables with at least one vote.
      # The vote count for each voteable is available as #vote_count.
      #
      # Options:
      #  :start_at    - Restrict the votes to those created after a certain time
      #  :end_at      - Restrict the votes to those created before a certain time
      #  :conditions  - A piece of SQL conditions to add to the query
      #  :limit       - The maximum number of voteables to return
      #  :order       - A piece of SQL to order by. Eg 'vote_count DESC' or 'voteable.created_at DESC'
      #  :at_least    - Item must have at least X votes
      #  :at_most     - Item may not have more than X votes
      def tally(*args)
        options = args.extract_options!
        t = self.where("#{Vote.table_name}.voteable_type = '#{self.name}'")
        # We join so that you can order by columns on the voteable model.
        t = t.joins("LEFT OUTER JOIN #{Vote.table_name} ON #{self.table_name}.#{self.primary_key} = #{Vote.table_name}.voteable_id")
        t = t.having("vote_count > 0")
        t = t.group("#{Vote.table_name}.voteable_id")
        t = t.limit(options[:limit]) if options[:limit]
        t = t.where("#{Vote.table_name}.created_at >= ?", options[:start_at]) if options[:start_at]
        t = t.where("#{Vote.table_name}.created_at <= ?", options[:end_at]) if options[:end_at]
        t = t.where(options[:conditions]) if options[:conditions]
        t = options[:order] ? t.order(options[:order]) : t.order("vote_count DESC")
        t = t.having(["vote_count >= ?", options[:at_least]]) if options[:at_least]
        t = t.having(["vote_count <= ?", options[:at_most]]) if options[:at_most]
        t.select("#{self.table_name}.*, COUNT(#{Vote.table_name}.voteable_id) AS vote_count")
      end

    end

    module InstanceMethods
      
      def golds
        self.votes.count(:conditions => {:vote => ActsAsVoter::InstanceMethods::VALUES[:gold]})
      end
      
      def silvers
        self.votes.count(:conditions => {:vote => ActsAsVoter::InstanceMethods::VALUES[:silver]})
      end
      
      def bronzes
        self.votes.count(:conditions => {:vote => ActsAsVoter::InstanceMethods::VALUES[:bronze]})
      end

      def votes_for
        self.votes.count(:conditions => {:vote => 1})
      end

      def votes_against
        self.votes.count(:conditions => {:vote => -1})
      end

      # You'll probably want to use this method to display how 'good' a particular voteable
      # is, and/or sort based on it.
      def plusminus
        votes_for - votes_against
      end

      def votes_count
        self.votes.size
      end
      
      def votes_total
        self.votes.sum(:vote)
      end

      def voters_who_voted
        self.votes.map(&:voter).uniq
      end

      def voted_by?(voter)
        0 < Vote.where(
              :voteable_id => self.id,
              :voteable_type => self.class.name,
              :voter_type => voter.class.name,
              :voter_id => voter.id
            ).count
      end

    end
  end
end
