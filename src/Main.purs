module Main where

import Prelude

import Data.Generic.Rep (class Generic)
import Data.Time.Duration (Milliseconds(..))
import Effect (Effect)
import Effect.Aff (delay, launchAff_)
import Effect.Class (liftEffect)
import Effect.Console (log)
import HTTPurple (ok, serve) as HTTP
import Routing.Duplex as RD
import Routing.Duplex.Generic as RG


data Route = SayHello

derive instance Generic Route _

route :: RD.RouteDuplex' Route
route = RD.root $ RG.sum
  { "SayHello": RG.noArgs
  }

main :: Effect Unit
main = do
  shutdown <- HTTP.serve { hostname: "localhost", port: 3000, onStarted } { route, router: const $ HTTP.ok "Go Away!" }
  launchAff_ $ do
    delay (Milliseconds 2000.0) 
    liftEffect $ log "Shutting down server..."
    liftEffect $ shutdown $ log "Server shutdown"
  where
  onStarted = do
    log " ┌───────────────────────────────────────────────┐"
    log " │ Server now up on port 3000                    │"
    log " │                                               │"
    log " │ To test, run:                                 │"
    log " │  > curl localhost:3000   # => Go Away!        │"
    log " └───────────────────────────────────────────────┘"