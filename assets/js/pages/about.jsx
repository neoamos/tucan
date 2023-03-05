import React from "react";

import { MainHeader } from "../layout";
import { ScrollToTop } from "../components/scroll"
import { useTitle } from "../components/ui_elements"
import { Link } from "react-router-dom"

export default function About(){
  useTitle("About", [])
  return (
    <div style={{height: "100%"}}>
      <ScrollToTop />
      <MainHeader>
        <h2>About</h2>
      </MainHeader>
      <div className="padding pre">
      <p>Tucan is a "light" Nostr client which is currently under development by <Link to={"/profile/npub1n6rlug259nhkkyrkxd84uq0kzn9ut04zyvv8kpudadru9aezqkmqwkk065"}>@amos</Link>.  It uses a central server to collect, store, and pre-process events, saving the client from having to do a lot of expensive work.</p>

      <p>Event signing and broadcasting happens on the client side.</p>
      
      <p>There are still many things missing, but the basic functionality is present.</p>

      <h3>What are the benefits of a "light" client?</h3>

      <p><b>Speed.</b>  The work done by the central server lets clients request and get exactly what it needs in one shot.</p>
      <p><b>Reduced resource usage on the client.</b> Normal clients use a lot of data transfer and CPU to process all the events it receives.</p>
      <p><b>Reduced load on relays.</b></p>
      <p><b>Persistent global view of Nostr.</b></p>
      <p><b>Better filtering of global feed.</b>  The global view of the network will let us filter spam more effecitvely.</p>

      <h3>Icon Attribution</h3>
      <a href="https://www.flaticon.com/free-icons/fauna" title="fauna icons">Fauna icons created by Freepik - Flaticon</a>
      </div>
    </div>
  )
}