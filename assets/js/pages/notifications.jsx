import React from "react";

import { MainHeader } from "../layout";
import { ScrollToTop } from "../components/scroll"

import { useTitle } from "../components/ui_elements"

export default function Notifications(){
  useTitle("Notifications")
  return (
    <div style={{height: "100%"}}>
      <ScrollToTop />
      <MainHeader>
        <h2>Notifications</h2>
      </MainHeader>
      <div className="padding">
        Notifications coming soon.
      </div>
    </div>
  )
}