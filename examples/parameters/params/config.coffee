params = [
  {
      name: 'width',
      type: 'float',
      default: 30,
      caption: "Width of the cube:",
    },
    {
      name: 'height',
      type: 'float',
      default: 15,
      caption: "Height of the cube:",
    },
    {
      name: 'depth',
      type: 'float',
      default: 25,
      caption: "Depth of the cube:",
    },
    {
      name: 'roundings',
      type: 'checkbox',
      default: false,
      caption : "Corner roundings are niice",
    },
    {
      name: 'wheels',
      type: 'select',
      default: null,
      values: "space,boxy",
      caption : "Not really wheels though",
    },
    {
      name: 'boxColor',
      type: 'color',
      default: '#FF0000',
      caption : "Pretty"
    },
    {
      name: 'boxColor2',
      type: 'color',
      default: '#FF5500',
      caption : "Pretty"
    },
    {
      name:'vary',
      type:'slider',
      default:5,
      max:100,
      min:0,
      step:0.5,
      caption: "wow I can sliiiide"
    },
    {
      name:'xpos',
      type:'slider',
      default:15,
      max:100,
      min:0,
      step:0.5,
      caption: "xpos"
    },
    {
      name:'ypos',
      type:'slider',
      default:15,
      max:100,
      min:0,
      step:0.5,
      caption: "ypos"
    },
        {
      name:'zpos',
      type:'slider',
      default:15,
      max:100,
      min:0,
      step:0.5,
      caption: "zpos"
    }
    ]