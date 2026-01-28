import React, { useState } from 'react';
import Toolbar from './components/Toolbar';
import PropertyBar from './components/PropertyBar';
import Canvas from './components/Canvas';
import AIPanel from './components/AIPanel';
import ExportModal from './components/ExportModal';
import RightPanel from './components/RightPanel';
import { VectorPath, ToolType, PathNode } from './types';

function App() {
  const [activeTool, setActiveTool] = useState<ToolType>(ToolType.PEN);
  const [paths, setPaths] = useState<VectorPath[]>([]);
  const [selectedPathId, setSelectedPathId] = useState<string | null>(null);
  
  // Dialog states
  const [isAIModalOpen, setIsAIModalOpen] = useState(false);
  const [isExportModalOpen, setIsExportModalOpen] = useState(false);

  const selectedPath = paths.find(p => p.id === selectedPathId) || null;

  const handleUpdatePath = (changes: Partial<VectorPath>) => {
    if (!selectedPathId) return;
    setPaths(prev => prev.map(p => 
      p.id === selectedPathId ? { ...p, ...changes } : p
    ));
  };

  const handleNodesUpdate = (pathId: string, nodes: PathNode[]) => {
      setPaths(prev => prev.map(p =>
        p.id === pathId ? { ...p, nodes } : p
      ));
  };
  
  const handleAddPath = (path: VectorPath) => {
      setPaths(prev => [...prev, path]);
  };
  
  const handleImportPaths = (newPaths: VectorPath[]) => {
      setPaths(prev => [...prev, ...newPaths]);
      if (newPaths.length > 0) {
          setSelectedPathId(newPaths[newPaths.length - 1].id);
          setActiveTool(ToolType.SELECT);
      }
  };

  return (
    <div className="flex flex-col h-screen w-screen bg-[#1e1e1e] text-[#e0e0e0] font-sans">
      {/* Top Bar */}
      <PropertyBar 
        selectedPath={selectedPath}
        onUpdatePath={handleUpdatePath}
        onOpenAI={() => setIsAIModalOpen(true)}
        onExport={() => setIsExportModalOpen(true)}
      />

      <div className="flex flex-1 overflow-hidden">
        {/* Left Toolbar */}
        <Toolbar 
            activeTool={activeTool} 
            onSelectTool={setActiveTool} 
            onClear={() => {
                if(window.confirm("Clear all paths?")) {
                    setPaths([]);
                    setSelectedPathId(null);
                }
            }}
        />

        {/* Main Canvas */}
        <Canvas 
            paths={paths}
            selectedPathId={selectedPathId}
            activeTool={activeTool}
            onPathUpdate={handleNodesUpdate}
            onSelectPath={setSelectedPathId}
            onAddPath={handleAddPath}
        />
        
        {/* Right Panel - Layers / Import */}
        <RightPanel onImport={handleImportPaths} />
      </div>

      {/* Modals */}
      <AIPanel 
        isOpen={isAIModalOpen} 
        onClose={() => setIsAIModalOpen(false)}
        onGenerated={(newPath) => {
            handleAddPath(newPath);
            setSelectedPathId(newPath.id);
            setActiveTool(ToolType.SELECT); // Switch to select to inspect the result
        }}
      />
      
      <ExportModal
        isOpen={isExportModalOpen}
        onClose={() => setIsExportModalOpen(false)}
        paths={paths}
      />
    </div>
  );
}

export default App;