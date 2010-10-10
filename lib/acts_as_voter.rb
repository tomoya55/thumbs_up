module ThumbsUp #:nodoc:
  module ActsAsVoter #:nodoc:

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def acts_as_voter

        # If a voting entity is deleted, keep the votes.
        # has_many :votes, :as => :voter, :dependent => :nullify
        # Destroy votes when a user is deleted.
        has_many :votes, :as => :voter, :dependent => :destroy

        include ThumbsUp::ActsAsVoter::InstanceMethods
        extend  ThumbsUp::ActsAsVoter::SingletonMethods
      end
    end

    # This module contains class methods
    module SingletonMethods
    end

    # This module contains instance methods
    module InstanceMethods
      VALUES = {
        :gold => 3, :silver => 2, :bronze => 1
      }
      
      
      # plusword
      def vote_gold(voteable)
        self.vote(voteable, { :value => VALUES[:gold], :exclusive => true })
      end
      
      def vote_silver(voteable)
        self.vote(voteable, { :value => VALUES[:silver], :exclusive => true })
      end
      
      def vote_bronze(voteable)
        self.vote(voteable, { :value => VALUES[:bronze], :exclusive => true })
      end
      
      def vote_gold?(voteable)
        vote_with?(voteable, VALUES[:gold])
      end
      
      def vote_silver?(voteable)
        vote_with?(voteable, VALUES[:silver])
      end
      
      def vote_bronze?(voteable)
        vote_with?(voteable, VALUES[:bronze])
      end
      
      def vote_with?(voteable, value)
        0 < Vote.where(:voter_id => self.id,
              :voter_type => self.class.name,
              :vote => value,
              :voteable_id => voteable.id,
              :voteable_type => voteable.class.name
            ).count
      end
      
      

      # Usage user.vote_count(:up)  # All +1 votes
      #       user.vote_count(:down) # All -1 votes
      #       user.vote_count()      # All votes

      def vote_count(for_or_against = :all)
        return self.votes.size if for_or_against == "all"
        self.votes.count(:conditions => {:vote => (for_or_against ? 1 : -1)}) 
      end

      def voted_for?(voteable)
        voted_which_way?(voteable, :up)
      end

      def voted_against?(voteable)
        voted_which_way?(voteable, :down)
      end

      def voted_on?(voteable)
        voteable.voted_by?(self)
      end

      def vote_for(voteable)
        self.vote(voteable, { :value => :up, :exclusive => false })
      end

      def vote_against(voteable)
        self.vote(voteable, { :value => :down, :exclusive => false })
      end

      def vote_exclusively_for(voteable)
        self.vote(voteable, { :value => :up, :exclusive => true })
      end

      def vote_exclusively_against(voteable)
        self.vote(voteable, { :value => :down, :exclusive => true })
      end

      def vote(voteable, options = {})
        raise ArgumentError "you must specify value in order to vote" unless options[:value]
        if options[:exclusive]
          self.clear_votes(voteable)
        end
        value = [:up, :down].include?(options[:value]) ? (options[:value] == :up ? 1 : -1) : options[:value].to_i
        Vote.create!(:vote => value, :voteable => voteable, :voter => self).tap do |v|
          voteable.reload_vote_counter if !v.new_record? and voteable.respond_to?(:reload_vote_counter)
        end
      end

      def clear_votes(voteable)
        Vote.where(
          :voter_id => self.id,
          :voter_type => self.class.name,
          :voteable_id => voteable.id,
          :voteable_type => voteable.class.name
        ).map(&:destroy)
      end

      def voted_which_way?(voteable, direction)
        raise ArgumentError, "expected :up or :down" unless [:up, :down].include?(direction)
        sql = direction == :up ? 'vote >= 1' : 'vote <= -1'
        0 < Vote.where(
              :voter_id => self.id,
              :voter_type => self.class.name,
              :voteable_id => voteable.id,
              :voteable_type => voteable.class.name
            ).where(sql).count
      end

    end
  end
end