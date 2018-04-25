import { createCipher } from 'crypto';

// pull in desired CSS/SASS files
require('./styles/main.scss');

// inject bundled Elm app into div#main
var Elm = require('../elm/Main');
var app = Elm.Main.embed(document.getElementById('main'));


app.ports.save.subscribe(function (project) {
  try {
    console.log(project);
    localStorage.setItem("project", JSON.stringify(project));
    alert("Project Saved!");
  } catch (e) {
    alert("Couldn't save :/")
  }
});

app.ports.download.subscribe(function (project) {
  downloadObjectAsJson(project, project.name)
});

app.ports.load.subscribe(function () {
  try {
    var project = localStorage.getItem("project");

    if (project) {
      project = JSON.parse(project);
      app.ports.loadProject.send(project);
    }
  } catch (e) {
    alert("Couldn't save :/")
  }
});

app.ports.loadFile.subscribe(function () {
  var file = document.getElementById("load-file").files[0];

  var reader = new FileReader();
  reader.onload = onReaderLoad;
  reader.readAsText(file);
});

function onReaderLoad(event) {
  var project = JSON.parse(event.target.result);
  app.ports.loadProject.send(project);
}


function downloadObjectAsJson(exportObj, exportName) {
  var dataStr = "data:text/json;charset=utf-8," + encodeURIComponent(JSON.stringify(exportObj));
  var downloadAnchorNode = document.createElement('a');
  downloadAnchorNode.setAttribute("href", dataStr);
  downloadAnchorNode.setAttribute("download", exportName + ".concept");
  downloadAnchorNode.click();
  downloadAnchorNode.remove();
}

