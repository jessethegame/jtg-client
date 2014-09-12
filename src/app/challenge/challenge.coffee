angular.module 'jtg'

.service 'Challenge', (jtg, toast, session, User) ->
  Challenge = jtg.model 'challenges'

  Challenge::init = ->
    @user = new User @user

  Challenge::boost = (amount) ->
    jtg
      .post "/challenges/#{@id}/points", {amount}
      .catch ({message}) ->
        toast message ? "Could not boost the challenge"
      .then ({user, challenge}) ->
        console.log {user, challenge}
      .then =>
        # TODO maybe return challenge and user total in response
        @points += amount
        session.user.points -= amount

  Challenge

.controller 'ChallengeCtrl', ($scope, Challenge, lock, reject, toast) ->
  $scope.createChallenge = lock "Creating challenge", ->
    return reject "That's not a challenge." unless $scope.challenge

    new Challenge $scope.challenge
      .create()
      .catch toast.create
      .then ->
        $scope.challenge = null

  $scope.challenges = Challenge.cache

  Challenge.index()

.directive 'challenge', ->
  restrict: 'E'
  templateUrl: 'app/challenge/challenge.html'
