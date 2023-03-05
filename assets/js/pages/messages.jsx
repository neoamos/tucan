import React from "react";

import { MainHeader } from "../layout";
import { ScrollToTop } from "../components/scroll"

import { useTitle } from "../components/ui_elements"

export default function Messages(){
  useTitle("Messages")
  return (
    <div style={{height: "100%"}}>
      <ScrollToTop />
      <MainHeader>
        <h2>Messages</h2>
      </MainHeader>
      <div className="padding">
        Messages comming soon.
      </div>
    </div>
  )
}