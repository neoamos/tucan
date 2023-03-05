import React from "react";

export default function Tabs(props){
  let tabs = props.tabs.map((tab, i) => {
    return (
      <Tab name={tab.name} active={props.activeTab == i} key={tab.name} onClick={() => {props.setActiveTab(i)}}/>
    )
  })
  return (
    <nav className="tabs">
        {tabs}
    </nav>
  )
}

function Tab(props){
  return (
    <div className={"tab ts " + (props.active ? "active" : "")} onClick={props.onClick}>
      <div className="tab-name">
        {props.name}
      </div>
      <div className={"tab-underline " + (props.active ? "active" : "")}></div>
    </div>
  )
}