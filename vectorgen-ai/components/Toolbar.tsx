import React from 'react';
import { PenTool, MousePointer2, Settings2 } from 'lucide-react';
import { ToolType } from '../types';

interface ToolbarProps {
  activeTool: ToolType;
  onSelectTool: (tool: ToolType) => void;
  onClear: () => void;
}

const Toolbar: React.FC<ToolbarProps> = ({ activeTool, onSelectTool, onClear }) => {
  const tools = [
    { id: ToolType.SELECT, icon: <MousePointer2 size={20} />, label: 'Select (V)' },
    { id: ToolType.NODE, icon: <Settings2 size={20} />, label: 'Direct Select (A)' },
    { id: ToolType.PEN, icon: <PenTool size={20} />, label: 'Pen Tool (P)' },
  ];

  return (
    <div className="w-14 bg-[#2b2b2b] border-r border-[#3a3a3a] flex flex-col items-center py-4 space-y-2 z-20">
      {tools.map((tool) => (
        <button
          key={tool.id}
          onClick={() => onSelectTool(tool.id)}
          title={tool.label}
          className={`p-3 rounded-lg transition-all duration-200 ${
            activeTool === tool.id
              ? 'bg-[#0078d4] text-white shadow-md'
              : 'text-[#a0a0a0] hover:bg-[#3a3a3a] hover:text-white'
          }`}
        >
          {tool.icon}
        </button>
      ))}

      <div className="h-px w-8 bg-[#3a3a3a] my-2" />
      
       <button
        onClick={onClear}
        className="text-[#a0a0a0] hover:text-red-400 text-xs mt-auto font-medium"
      >
        CLEAR
      </button>
    </div>
  );
};

export default Toolbar;